extends Node
## Autoload : run en cours, progression, sauvegarde, options, modificateurs, audio.

const VERSION := "2.0.0"
const SAVE_PATH := "user://save.cfg"
const LevelData = preload("res://scripts/level_data.gd")
const Story = preload("res://scripts/story.gd")
const Sfx = preload("res://scripts/sfx.gd")
const STAGE_COUNT := 5

const GRAVITY_NAMES: Array[String] = ["Lunaire", "Normale", "Lourde"]
const GRAVITY_SCALES: Array[float] = [0.45, 1.0, 1.5]

## Modificateurs à cocher : clé, nom, multiplicateur de score
const TOGGLES := [
	["speed", "Vitesse x1.5", 1.25],
	["timer", "Contre-la-montre (temps limité)", 1.2],
	["hardcore", "Hardcore (une chute = fin de run)", 1.8],
	["no_double", "Sans double saut", 1.5],
	["mirror", "Niveaux en miroir", 1.1],
	["ice", "Sol glissant (glace)", 1.2],
	["wind", "Vent changeant", 1.2],
	["crumble", "Toutes les dalles s'effondrent", 1.4],
	["lava", "Lave qui monte", 1.5],
	["fog", "Brouillard épais", 1.15],
	["invert", "Commandes inversées", 1.3],
]

var run: Dictionary = {}
var pending_story: Dictionary = {}

var best_run_score: int = 0
var best_run_time: float = 0.0
var runs_completed: int = 0
var best_stage: int = 0

var mods: Dictionary = {}
var options: Dictionary = {
	"master": 0.8, "music": 0.5, "sfx": 0.8,
	"sens": 1.0, "fov": 75.0, "invert_y": false,
	"fullscreen": false, "shadows": true, "hint": true,
}

var sounds: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_theme := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_mods(false)
	reset_run(12345)
	_setup_input()
	_setup_theme()
	_setup_audio()
	load_game()
	apply_options()


# ---------------------------------------------------------------- modificateurs

func gravity_scale() -> float:
	return GRAVITY_SCALES[clampi(int(mods["gravity"]), 0, 2)]


func speed_scale() -> float:
	return 1.5 if mods["speed"] else 1.0


func multiplier() -> float:
	var m := 1.0
	match int(mods["gravity"]):
		0: m *= 0.8
		2: m *= 1.4
	for t in TOGGLES:
		if mods[t[0]]:
			m *= float(t[2])
	return m


func mod_summary() -> String:
	var parts: Array[String] = []
	if int(mods["gravity"]) != 1:
		parts.append("Gravité " + GRAVITY_NAMES[int(mods["gravity"])].to_lower())
	for t in TOGGLES:
		if mods[t[0]]:
			parts.append(String(t[1]).split(" (")[0])
	if parts.is_empty():
		return "Aucun modificateur"
	return ", ".join(parts)


func randomize_mods() -> void:
	mods["gravity"] = randi() % 3
	for t in TOGGLES:
		mods[t[0]] = randf() < 0.22
	save_game()


func reset_mods(save: bool = true) -> void:
	mods["gravity"] = 1
	for t in TOGGLES:
		mods[t[0]] = false
	if save:
		save_game()


# ---------------------------------------------------------------- run

func reset_run(seed_value: int) -> void:
	run = {"seed": seed_value, "stage": 0, "time": 0.0, "score": 0, "deaths": 0, "coins": 0, "active": false}


func daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


func start_run(seed_value: int, skip_intro: bool = false) -> void:
	reset_run(seed_value)
	run["active"] = true
	if skip_intro:
		show_stage_story()
	else:
		_story(Story.INTRO_TITLE, Story.INTRO, 0, "stage_story", "Commencer l'aventure")


func show_stage_story() -> void:
	var st: int = run["stage"]
	best_stage = maxi(best_stage, st + 1)
	var info: Dictionary = Story.STAGES[st]
	_story(info["title"], info["before"], st, "level", "C'est parti !")


func stage_cleared(t: float, score: int, coins: int, deaths: int) -> void:
	run["time"] = float(run["time"]) + t
	run["score"] = int(run["score"]) + score
	run["coins"] = int(run["coins"]) + coins
	run["deaths"] = int(run["deaths"]) + deaths
	if int(run["stage"]) + 1 >= STAGE_COUNT:
		_finish_run()
	else:
		run["stage"] = int(run["stage"]) + 1
		show_stage_story()


func _finish_run() -> void:
	run["active"] = false
	var bonus := int(1000 * multiplier())
	run["score"] = int(run["score"]) + bonus
	runs_completed += 1
	var new_best := false
	if int(run["score"]) > best_run_score:
		best_run_score = int(run["score"])
		best_run_time = float(run["time"])
		new_best = true
	save_game()
	var text: String = Story.ENDING + "\n\n— Résultat de la run —\n"
	text += "Score : %d (bonus de fin +%d)%s\n" % [int(run["score"]), bonus, "  (nouveau record !)" if new_best else ""]
	text += "Temps : %s   •   Pièces : %d   •   Chutes : %d\n" % [format_time(float(run["time"])), int(run["coins"]), int(run["deaths"])]
	text += "Seed : %d   •   %s" % [int(run["seed"]), mod_summary()]
	_story(Story.ENDING_TITLE, text, 4, "menu", "Retour au menu")


func fail_run() -> void:
	run["active"] = false
	save_game()


func _story(title: String, text: String, theme_idx: int, next: String, button: String) -> void:
	pending_story = {"title": title, "text": text, "theme": theme_idx, "next": next, "button": button}
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/story.tscn")


func format_time(t: float) -> String:
	return "%02d:%04.1f" % [int(t / 60.0), fmod(t, 60.0)]


# ---------------------------------------------------------------- sauvegarde

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "best_run_score", best_run_score)
	cfg.set_value("progress", "best_run_time", best_run_time)
	cfg.set_value("progress", "runs_completed", runs_completed)
	cfg.set_value("progress", "best_stage", best_stage)
	cfg.set_value("mods", "all", mods)
	cfg.set_value("options", "all", options)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	best_run_score = int(cfg.get_value("progress", "best_run_score", 0))
	best_run_time = float(cfg.get_value("progress", "best_run_time", 0.0))
	runs_completed = int(cfg.get_value("progress", "runs_completed", 0))
	best_stage = int(cfg.get_value("progress", "best_stage", 0))
	var saved: Dictionary = cfg.get_value("mods", "all", {})
	for k in saved:
		if mods.has(k):
			mods[k] = saved[k]
	var opts: Dictionary = cfg.get_value("options", "all", {})
	for k in opts:
		if options.has(k):
			options[k] = opts[k]


# ---------------------------------------------------------------- options / audio

func apply_options() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(options["master"]), 0.0001)))
	if _music_player:
		_music_player.volume_db = linear_to_db(maxf(float(options["music"]), 0.0001))
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if options["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _setup_audio() -> void:
	sounds = Sfx.build_all()
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)


func play_sfx(sfx_name: String, pitch: float = 1.0, db: float = 0.0) -> void:
	if not sounds.has(sfx_name):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = sounds[sfx_name]
			p.pitch_scale = pitch
			p.volume_db = db + linear_to_db(maxf(float(options["sfx"]), 0.0001))
			p.play()
			return


func play_music(theme_idx: int) -> void:
	if theme_idx == _music_theme and _music_player.playing:
		return
	_music_theme = theme_idx
	_music_player.stream = Sfx.music(theme_idx)
	_music_player.volume_db = linear_to_db(maxf(float(options["music"]), 0.0001))
	_music_player.play()


func stop_music() -> void:
	_music_theme = -1
	_music_player.stop()


# ---------------------------------------------------------------- entrées / thème

func _setup_input() -> void:
	# Touches physiques : WASD correspond à ZQSD sur un clavier AZERTY.
	_add_action("forward", [KEY_W, KEY_UP])
	_add_action("back", [KEY_S, KEY_DOWN])
	_add_action("left", [KEY_A, KEY_LEFT])
	_add_action("right", [KEY_D, KEY_RIGHT])
	_add_action("jump", [KEY_SPACE])
	_add_action("pause", [KEY_ESCAPE, KEY_P])
	_add_action("restart", [KEY_R])


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


func _setup_theme() -> void:
	var theme := Theme.new()
	theme.default_font_size = 22
	var colors := {
		"normal": Color(0.16, 0.20, 0.34),
		"hover": Color(0.26, 0.34, 0.58),
		"pressed": Color(0.10, 0.13, 0.24),
		"disabled": Color(0.11, 0.12, 0.16),
		"focus": Color(0.0, 0.0, 0.0, 0.0),
	}
	for s in colors:
		var sb := StyleBoxFlat.new()
		sb.bg_color = colors[s]
		sb.set_corner_radius_all(10)
		sb.set_content_margin_all(10)
		sb.set_border_width_all(2)
		sb.border_color = Color(0.5, 0.8, 1.0, 0.55) if s != "focus" else Color(1, 1, 1, 0.8)
		if s == "focus":
			sb.draw_center = false
		theme.set_stylebox(String(s), "Button", sb)
	theme.set_color("font_disabled_color", "Button", Color(0.5, 0.5, 0.56))
	get_tree().root.theme = theme

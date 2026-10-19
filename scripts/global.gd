extends Node
## Autoload : run en cours, progression, sauvegarde, options, modificateurs, succès, apparences, audio.

const VERSION := "3.0.0"
const SAVE_PATH := "user://save.cfg"
const LevelData = preload("res://scripts/level_data.gd")
const Story = preload("res://scripts/story.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Achievements = preload("res://scripts/achievements.gd")

const GRAVITY_NAMES: Array[String] = ["Lunaire", "Normale", "Lourde"]
const GRAVITY_SCALES: Array[float] = [0.45, 1.0, 1.5]
const GRAVITY_MULT: Array[float] = [0.8, 1.0, 1.4]
const LENGTH_NAMES: Array[String] = ["Normale (x1)", "Longue (x1.5)", "Très longue (x2)", "Marathon (x3)"]
const LENGTH_FACTORS: Array[float] = [1.0, 1.5, 2.0, 3.0]
const LENGTH_MULT: Array[float] = [1.0, 1.15, 1.3, 1.6]
const DIFFICULTY_NAMES: Array[String] = ["Détendu", "Normal", "Expert"]
const DIFFICULTY_MULT: Array[float] = [0.8, 1.0, 1.3]
const QUALITY_NAMES: Array[String] = ["Basse", "Moyenne", "Élevée"]

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

## Apparences de Lumi : débloquées avec le total de pièces ramassées
const SKINS := [
	{"id": "orange", "name": "Orange", "color": Color(1.0, 0.55, 0.15), "cost": 0},
	{"id": "blue", "name": "Bleu", "color": Color(0.2, 0.5, 1.0), "cost": 40},
	{"id": "green", "name": "Vert", "color": Color(0.25, 0.85, 0.4), "cost": 80},
	{"id": "pink", "name": "Rose", "color": Color(1.0, 0.4, 0.75), "cost": 140},
	{"id": "violet", "name": "Violet", "color": Color(0.6, 0.35, 0.95), "cost": 200},
	{"id": "gold", "name": "Or", "color": Color(1.0, 0.82, 0.2), "cost": 320},
	{"id": "dark", "name": "Ombre", "color": Color(0.15, 0.15, 0.22), "cost": 450},
	{"id": "rainbow", "name": "Arc-en-ciel", "color": Color(1, 1, 1), "cost": 600},
]

var run: Dictionary = {}
var pending_story: Dictionary = {}

var records: Dictionary = {}
var stats: Dictionary = {}
var achievements: Dictionary = {}
var toasts: Array = [] # succès à annoncer en jeu

var mods: Dictionary = {}
var options: Dictionary = {}

var sounds: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_theme := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_mods(false)
	reset_options()
	reset_stats()
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


func length_factor() -> float:
	return LENGTH_FACTORS[clampi(int(mods["length"]), 0, 3)]


func multiplier() -> float:
	var m: float = GRAVITY_MULT[clampi(int(mods["gravity"]), 0, 2)]
	m *= LENGTH_MULT[clampi(int(mods["length"]), 0, 3)]
	m *= DIFFICULTY_MULT[clampi(int(mods["difficulty"]), 0, 2)]
	for t in TOGGLES:
		if mods[t[0]]:
			m *= float(t[2])
	return m


func active_mod_count() -> int:
	var n := 0
	if int(mods["gravity"]) != 1: n += 1
	if int(mods["length"]) != 0: n += 1
	if int(mods["difficulty"]) != 1: n += 1
	for t in TOGGLES:
		if mods[t[0]]: n += 1
	return n


func mod_summary() -> String:
	var parts: Array[String] = []
	if int(mods["gravity"]) != 1:
		parts.append("Gravité " + GRAVITY_NAMES[int(mods["gravity"])].to_lower())
	if int(mods["length"]) != 0:
		parts.append("Longueur " + LENGTH_NAMES[int(mods["length"])].split(" (")[0].to_lower())
	if int(mods["difficulty"]) != 1:
		parts.append("Difficulté " + DIFFICULTY_NAMES[int(mods["difficulty"])].to_lower())
	for t in TOGGLES:
		if mods[t[0]]:
			parts.append(String(t[1]).split(" (")[0])
	if parts.is_empty():
		return "Aucun modificateur"
	return ", ".join(parts)


func randomize_mods() -> void:
	mods["gravity"] = randi() % 3
	mods["length"] = randi() % 3
	mods["difficulty"] = 1
	for t in TOGGLES:
		mods[t[0]] = randf() < 0.22
	save_game()


func reset_mods(save: bool = true) -> void:
	mods = {"gravity": 1, "length": 0, "difficulty": 1}
	for t in TOGGLES:
		mods[t[0]] = false
	if save:
		save_game()


func reset_options() -> void:
	options = {
		"master": 0.8, "music": 0.5, "sfx": 0.8,
		"sens": 1.0, "fov": 75.0, "invert_y": false,
		"fullscreen": false, "shadows": true, "hint": true,
		"quality": 0 if is_touch_device() else 2,
		"touch": 0, "touch_scale": 1.0, "vibration": true,
		"skin": "orange",
	}


func reset_stats() -> void:
	records = {}
	stats = {"coins": 0, "jumps": 0, "falls": 0, "stages": 0, "runs": 0, "playtime": 0.0, "worlds": []}
	achievements = {}


# ---------------------------------------------------------------- plateforme / mobile

func is_touch_device() -> bool:
	if OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(window.matchMedia && window.matchMedia('(pointer: coarse)').matches)")
		return bool(v)
	return false


func use_touch_controls() -> bool:
	match int(options["touch"]):
		1: return true
		2: return false
	return is_touch_device()


func vibrate(ms: int = 40) -> void:
	if options["vibration"] and is_touch_device():
		Input.vibrate_handheld(ms)


func quality() -> int:
	return clampi(int(options["quality"]), 0, 2)


## Marges de sécurité (encoche, coins arrondis) en pixels de l'écran virtuel. Zéro hors mobile.
func safe_margins() -> Dictionary:
	var m := {"left": 0, "top": 0, "right": 0, "bottom": 0}
	if not is_touch_device():
		return m
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return m
	var vp := get_viewport().get_visible_rect().size
	var sx := vp.x / float(win.x)
	var sy := vp.y / float(win.y)
	m["left"] = int(maxf(safe.position.x, 0.0) * sx)
	m["top"] = int(maxf(safe.position.y, 0.0) * sy)
	m["right"] = int(maxf(float(win.x) - float(safe.end.x), 0.0) * sx)
	m["bottom"] = int(maxf(float(win.y) - float(safe.end.y), 0.0) * sy)
	return m


# ---------------------------------------------------------------- apparences

func skin_by_id(id: String) -> Dictionary:
	for s in SKINS:
		if s["id"] == id:
			return s
	return SKINS[0]


func unlocked_skins() -> Array:
	var out: Array = []
	for s in SKINS:
		if int(stats["coins"]) >= int(s["cost"]):
			out.append(s)
	return out


func current_skin() -> Dictionary:
	var s := skin_by_id(String(options["skin"]))
	if int(stats["coins"]) < int(s["cost"]):
		return SKINS[0]
	return s


# ---------------------------------------------------------------- run

func reset_run(seed_value: int) -> void:
	run = {
		"seed": seed_value, "mode": "adventure", "stages": [0], "stage": 0,
		"time": 0.0, "score": 0, "deaths": 0, "coins": 0, "active": false, "daily": false,
	}


func daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d["year"]) * 10000 + int(d["month"]) * 100 + int(d["day"])


## 5 mondes pour la Run éclair : un par palier de difficulté, tirés selon la seed.
func quick_worlds(seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, 4242])
	var groups := [[0, 1], [2, 3], [4, 5, 6], [7, 8], [9, 10, 11]]
	var out: Array = []
	for g in groups:
		out.append(g[rng.randi() % g.size()])
	return out


func current_theme() -> int:
	var st: Array = run["stages"]
	return int(st[clampi(int(run["stage"]), 0, st.size() - 1)])


func stage_total() -> int:
	return (run["stages"] as Array).size()


## mode : "adventure" (12 mondes), "quick" (5 mondes) ou "free" (un monde : worlds[0])
func start_run(seed_value: int, mode: String = "adventure", worlds: Array = [], skip_intro: bool = false, daily: bool = false) -> void:
	reset_run(seed_value)
	run["mode"] = mode
	run["active"] = true
	run["daily"] = daily
	match mode:
		"quick": run["stages"] = quick_worlds(seed_value)
		"free": run["stages"] = [int(worlds[0]) if not worlds.is_empty() else 0]
		_: run["stages"] = range(LevelData.WORLD_COUNT)
	if mode == "free":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	elif skip_intro:
		show_stage_story()
	elif mode == "quick":
		_story(Story.QUICK_TITLE, Story.QUICK_INTRO, int(run["stages"][0]), "stage_story", "C'est parti !")
	else:
		_story(Story.INTRO_TITLE, Story.INTRO, 0, "stage_story", "Commencer l'aventure")


func show_stage_story() -> void:
	var theme_idx := current_theme()
	var info: Dictionary = Story.STAGES[theme_idx]
	var title: String = info["title"]
	if run["mode"] == "quick":
		title = "Étape %d/%d — %s" % [int(run["stage"]) + 1, stage_total(), LevelData.get_themes()[theme_idx]["name"]]
	_story(title, info["before"], theme_idx, "level", "C'est parti !")


## info : {time, score, coins, deaths}
func stage_cleared(info: Dictionary) -> void:
	run["time"] = float(run["time"]) + float(info["time"])
	run["score"] = int(run["score"]) + int(info["score"])
	run["coins"] = int(run["coins"]) + int(info["coins"])
	run["deaths"] = int(run["deaths"]) + int(info["deaths"])
	if int(run["stage"]) + 1 >= stage_total():
		_finish_run()
	else:
		run["stage"] = int(run["stage"]) + 1
		show_stage_story()


func record_key() -> String:
	if run["mode"] == "free":
		return "world_%d" % int((run["stages"] as Array)[0])
	return String(run["mode"])


func _finish_run() -> void:
	run["active"] = false
	var bonus := int(1000 * multiplier()) if run["mode"] != "free" else 0
	run["score"] = int(run["score"]) + bonus
	stats["runs"] = int(stats["runs"]) + 1
	var key := record_key()
	var new_best := false
	if not records.has(key) or int(run["score"]) > int((records[key] as Dictionary)["score"]):
		records[key] = {"score": int(run["score"]), "time": float(run["time"])}
		new_best = true
	var got := Achievements.evaluate_run(self, String(run["mode"]), bool(mods["hardcore"]), bool(run["daily"]))
	toasts.append_array(got)
	save_game()
	var text := ""
	var title := Story.WORLD_ENDING_TITLE
	match String(run["mode"]):
		"adventure":
			title = Story.ENDING_TITLE
			text = Story.ENDING + "\n\n"
		"quick":
			title = Story.QUICK_ENDING_TITLE
			text = Story.QUICK_ENDING + "\n\n"
		_:
			text = "%s terminé !\n\n" % LevelData.get_themes()[int((run["stages"] as Array)[0])]["name"]
	text += "— Résultat —\nScore : %d%s%s\n" % [int(run["score"]), (" (bonus de fin +%d)" % bonus) if bonus > 0 else "", "  (nouveau record !)" if new_best else ""]
	text += "Temps : %s   •   Pièces : %d   •   Chutes : %d\n" % [format_time(float(run["time"])), int(run["coins"]), int(run["deaths"])]
	text += "Seed : %d   •   %s" % [int(run["seed"]), mod_summary()]
	if not got.is_empty():
		var names: Array[String] = []
		for id in got:
			names.append(Achievements.name_of(String(id)))
		text += "\nSuccès débloqués : " + ", ".join(names)
	toasts.clear()
	_story(title, text, 11 if run["mode"] == "adventure" else int((run["stages"] as Array).back()), "menu", "Retour au menu")


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
	cfg.set_value("progress", "records", records)
	cfg.set_value("progress", "stats", stats)
	cfg.set_value("progress", "achievements", achievements)
	cfg.set_value("mods", "all", mods)
	cfg.set_value("options", "all", options)
	cfg.save(SAVE_PATH)


func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var rec: Dictionary = cfg.get_value("progress", "records", {})
	for k in rec:
		records[k] = rec[k]
	var st: Dictionary = cfg.get_value("progress", "stats", {})
	for k in st:
		if stats.has(k):
			stats[k] = st[k]
	achievements = cfg.get_value("progress", "achievements", {})
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
	if not is_touch_device():
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
	# Manette : stick gauche = déplacement, stick droit = caméra, A = saut, Start = pause
	_add_axis("left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("back", JOY_AXIS_LEFT_Y, 1.0)
	_add_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)
	_add_button("jump", JOY_BUTTON_A)
	_add_button("pause", JOY_BUTTON_START)
	_add_button("restart", JOY_BUTTON_Y)


func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)


func _add_axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	InputMap.action_add_event(action, e)


func _add_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var e := InputEventJoypadButton.new()
	e.button_index = button
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

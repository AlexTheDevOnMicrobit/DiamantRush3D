extends Node
## Autoload : run en cours, modes, progression, sauvegarde, options, modificateurs,
## succès, apparences, défis, codes de partage, fantômes, classement, audio.

const VERSION := "3.1.0"
const REPO := "AlexTheDevOnMicrobit/DiamantRush3D"
const SAVE_PATH := "user://save.cfg"
const GHOST_PATH := "user://ghosts.dat"
const LevelData = preload("res://scripts/level_data.gd")
const Story = preload("res://scripts/story.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Achievements = preload("res://scripts/achievements.gd")
const Translations = preload("res://scripts/translations.gd")

const GRAVITY_NAMES: Array[String] = ["Lunaire", "Normale", "Lourde"]
const GRAVITY_SCALES: Array[float] = [0.45, 1.0, 1.5]
const GRAVITY_MULT: Array[float] = [0.8, 1.0, 1.4]
const LENGTH_NAMES: Array[String] = ["Normale (x1)", "Longue (x1.5)", "Très longue (x2)", "Marathon (x3)"]
const LENGTH_FACTORS: Array[float] = [1.0, 1.5, 2.0, 3.0]
const LENGTH_MULT: Array[float] = [1.0, 1.15, 1.3, 1.6]
const DIFFICULTY_NAMES: Array[String] = ["Détendu", "Normal", "Expert"]
const DIFFICULTY_MULT: Array[float] = [0.8, 1.0, 1.3]
const QUALITY_NAMES: Array[String] = ["Basse", "Moyenne", "Élevée"]
const ENDLESS_LIVES := 3

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

## Touches remappables : action, libellé
const REMAP_ACTIONS := [
	["forward", "Avancer"], ["back", "Reculer"], ["left", "Gauche"], ["right", "Droite"],
	["jump", "Sauter"], ["pause", "Pause"], ["restart", "Recommencer"],
]
const DEFAULT_KEYS := {
	"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D,
	"jump": KEY_SPACE, "pause": KEY_ESCAPE, "restart": KEY_R,
}

const MUSIC_FILES := [
	"world_01_prairies", "world_02_foret", "world_03_dunes", "world_04_recif", "world_05_toundra", "world_06_cristaux",
	"world_07_usine", "world_08_ruines", "world_09_marais", "world_10_volcan", "world_11_neon", "world_12_ciel",
]

var run: Dictionary = {}
var pending_story: Dictionary = {}

var records: Dictionary = {}
var stats: Dictionary = {}
var achievements: Dictionary = {}
var leaderboard: Dictionary = {}
var challenges_done: Dictionary = {}
var toasts: Array = [] # succès à annoncer en jeu

var mods: Dictionary = {}
var mods_backup: Dictionary = {}
var options: Dictionary = {}

var sounds: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _jingle_player: AudioStreamPlayer
var _music_key := ""
var _ghosts: Dictionary = {}
var _ghosts_loaded := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_mods(false)
	reset_options()
	reset_stats()
	reset_run(12345)
	_setup_input()
	_setup_theme()
	_setup_audio()
	_setup_translations()
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
		parts.append(tr("Gravité") + " " + tr(GRAVITY_NAMES[int(mods["gravity"])]).to_lower())
	if int(mods["length"]) != 0:
		parts.append(tr("Longueur") + " " + tr(LENGTH_NAMES[int(mods["length"])].split(" (")[0]).to_lower())
	if int(mods["difficulty"]) != 1:
		parts.append(tr("Difficulté") + " " + tr(DIFFICULTY_NAMES[int(mods["difficulty"])]).to_lower())
	for t in TOGGLES:
		if mods[t[0]]:
			parts.append(tr(String(t[1]).split(" (")[0]))
	if parts.is_empty():
		return tr("Aucun modificateur")
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


func restore_mods() -> void:
	if not mods_backup.is_empty():
		mods = mods_backup
		mods_backup = {}


func reset_options() -> void:
	options = {
		"master": 0.8, "music": 0.5, "sfx": 0.8,
		"sens": 1.0, "fov": 75.0, "invert_y": false,
		"fullscreen": false, "shadows": true, "hint": true,
		"quality": 0 if is_touch_device() else 2,
		"touch": 0, "touch_scale": 1.0, "vibration": true,
		"skin": "orange",
		"assist": false, "symbols": false, "colorblind": false,
		"text_scale": 1.0, "ghost": true, "updates": true,
		"language": "auto", "keymap": {},
	}


func reset_stats() -> void:
	records = {}
	stats = {"coins": 0, "jumps": 0, "falls": 0, "stages": 0, "runs": 0, "playtime": 0.0, "worlds": [], "bosses": 0, "endless_best": 0}
	achievements = {}
	leaderboard = {"all": [], "endless": []}
	challenges_done = {}


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
		"lives": 0, "challenge": "", "objective": {}, "reward": 0, "challenge_kind": "",
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


func is_endless() -> bool:
	return run["mode"] == "endless"


## Monde de l'étape courante (le mode infini fait tourner les 12 mondes).
func current_theme() -> int:
	if is_endless():
		return int(run["stage"]) % LevelData.WORLD_COUNT
	var st: Array = run["stages"]
	return int(st[clampi(int(run["stage"]), 0, st.size() - 1)])


func stage_total() -> int:
	if is_endless():
		return 9999
	return (run["stages"] as Array).size()


## Réglages de génération supplémentaires (mode infini : difficulté croissante, étapes plus courtes, pas de boss).
func generation_extra() -> Dictionary:
	if is_endless():
		var st := int(run["stage"])
		return {"diff_bonus": float(st / LevelData.WORLD_COUNT) * 1.5 + float(st % LevelData.WORLD_COUNT) * 0.0,
			"allow_boss": false, "count_mult": minf(0.55 + float(st) * 0.02, 0.9)}
	return {}


## mode : "adventure" (12 mondes), "quick" (5 mondes), "free" (un monde : worlds[0]) ou "endless"
func start_run(seed_value: int, mode: String = "adventure", worlds: Array = [], skip_intro: bool = false, daily: bool = false) -> void:
	reset_run(seed_value)
	run["mode"] = mode
	run["active"] = true
	run["daily"] = daily
	match mode:
		"quick": run["stages"] = quick_worlds(seed_value)
		"free": run["stages"] = [int(worlds[0]) if not worlds.is_empty() else 0]
		"endless":
			run["stages"] = [0]
			run["lives"] = ENDLESS_LIVES
		_: run["stages"] = range(LevelData.WORLD_COUNT)
	if mode == "free" or mode == "endless":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	elif skip_intro:
		show_stage_story()
	elif mode == "quick":
		_story(Story.QUICK_TITLE, Story.QUICK_INTRO, int(run["stages"][0]), "stage_story", "C'est parti !")
	else:
		_story(Story.INTRO_TITLE, Story.INTRO, 0, "stage_story", "Commencer l'aventure")


## Relance la run en cours avec la même seed (conserve le défi éventuel).
func restart_run() -> void:
	var keep := {"challenge": run["challenge"], "objective": run["objective"], "reward": run["reward"], "challenge_kind": run["challenge_kind"]}
	start_run(int(run["seed"]), String(run["mode"]), run["stages"], true, bool(run["daily"]))
	for k in keep:
		run[k] = keep[k]


func show_stage_story() -> void:
	var theme_idx := current_theme()
	var info: Dictionary = Story.STAGES[theme_idx]
	var title: String = tr(info["title"])
	if run["mode"] == "quick":
		title = tr("Étape %d/%d — %s") % [int(run["stage"]) + 1, stage_total(), tr(LevelData.get_themes()[theme_idx]["name"])]
	_story(title, tr(info["before"]), theme_idx, "level", "C'est parti !")


## info : {time, score, coins, deaths}
func stage_cleared(info: Dictionary) -> void:
	run["time"] = float(run["time"]) + float(info["time"])
	run["score"] = int(run["score"]) + int(info["score"])
	run["coins"] = int(run["coins"]) + int(info["coins"])
	run["deaths"] = int(run["deaths"]) + int(info["deaths"])
	if is_endless():
		run["stage"] = int(run["stage"]) + 1
		stats["endless_best"] = maxi(int(stats["endless_best"]), int(run["stage"]))
		if int(run["stage"]) % 3 == 0:
			run["lives"] = mini(int(run["lives"]) + 1, ENDLESS_LIVES + 2)
		if int(run["stage"]) >= 10 and not achievements.has("endless_10"):
			achievements["endless_10"] = true
			toasts.append("endless_10")
		save_game()
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/level.tscn")
	elif int(run["stage"]) + 1 >= stage_total():
		_finish_run()
	else:
		run["stage"] = int(run["stage"]) + 1
		show_stage_story()


func record_key() -> String:
	if run["mode"] == "free":
		return "world_%d" % int((run["stages"] as Array)[0])
	return String(run["mode"])


## Ajoute un score au classement local (top 10 général, top 10 mode infini).
func add_score(mode: String, score: int, stages: int, seed_value: int) -> int:
	var entry := {"score": score, "mode": mode, "stages": stages, "seed": seed_value, "date": Time.get_date_string_from_system()}
	var rank := -1
	for list_key in (["all", "endless"] if mode == "endless" else ["all"]):
		var list: Array = leaderboard[list_key]
		list.append(entry)
		list.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
		if list.size() > 10:
			list.resize(10)
		if list_key == "all" or mode == "endless":
			rank = list.find(entry) + 1 if list.has(entry) else -1
	return rank


## Évalue l'objectif d'un défi : {type: falls|coins|time|nofall, value}
func objective_met(obj: Dictionary) -> bool:
	match String(obj.get("type", "")):
		"falls": return int(run["deaths"]) <= int(obj["value"])
		"nofall": return int(run["deaths"]) == 0
		"coins": return int(run["coins"]) >= int(obj["value"])
		"time": return float(run["time"]) <= float(obj["value"])
	return true


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
	var rank := add_score(String(run["mode"]), int(run["score"]), stage_total(), int(run["seed"]))
	var got := Achievements.evaluate_run(self, String(run["mode"]), bool(mods["hardcore"]), bool(run["daily"]))
	var challenge_text := ""
	if String(run["challenge"]) != "":
		var ok := objective_met(run["objective"])
		var ckey := String(run["challenge"])
		if ok and not challenges_done.has(ckey):
			challenges_done[ckey] = true
			stats["coins"] = int(stats["coins"]) + int(run["reward"])
			if not achievements.has("challenge"):
				achievements["challenge"] = true
				got.append("challenge")
			challenge_text = tr("Défi réussi ! +%d pièces") % int(run["reward"])
		elif ok:
			challenge_text = tr("Défi déjà réussi.")
		else:
			challenge_text = tr("Défi manqué : ") + challenge_objective_text(run["objective"])
	save_game()
	var text := ""
	var title := tr(Story.WORLD_ENDING_TITLE)
	match String(run["mode"]):
		"adventure":
			title = tr(Story.ENDING_TITLE)
			text = tr(Story.ENDING) + "\n\n"
		"quick":
			title = tr(Story.QUICK_ENDING_TITLE)
			text = tr(Story.QUICK_ENDING) + "\n\n"
		_:
			text = tr("%s terminé !") % tr(LevelData.get_themes()[int((run["stages"] as Array)[0])]["name"]) + "\n\n"
	text += tr("— Résultat —") + "\n" + tr("Score : %d") % int(run["score"])
	if bonus > 0:
		text += " " + (tr("(bonus de fin +%d)") % bonus)
	if new_best:
		text += "  " + tr("(nouveau record !)")
	text += "\n" + tr("Temps : %s   •   Pièces : %d   •   Chutes : %d") % [format_time(float(run["time"])), int(run["coins"]), int(run["deaths"])] + "\n"
	text += tr("Seed : %d") % int(run["seed"]) + "   •   " + mod_summary()
	if rank > 0:
		text += "\n" + tr("Classement local : n°%d") % rank
	if challenge_text != "":
		text += "\n" + challenge_text
	if not got.is_empty():
		var names: Array[String] = []
		for id in got:
			names.append(tr(Achievements.name_of(String(id))))
		text += "\n" + tr("Succès débloqués : ") + ", ".join(names)
	toasts.clear()
	_story(title, text, 11 if run["mode"] == "adventure" else int((run["stages"] as Array).back()), "menu", "Retour au menu")
	pending_story["jingle"] = "run_complete"


## Fin d'une run perdue ou abandonnée : le score cumulé entre quand même au classement.
func fail_run() -> int:
	var rank := -1
	if run["active"] and int(run["score"]) > 0:
		rank = add_score(String(run["mode"]), int(run["score"]), int(run["stage"]) + (1 if not is_endless() else 0), int(run["seed"]))
	run["active"] = false
	save_game()
	return rank


func _story(title: String, text: String, theme_idx: int, next: String, button: String) -> void:
	pending_story = {"title": title, "text": text, "theme": theme_idx, "next": next, "button": button}
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/story.tscn")


func format_time(t: float) -> String:
	return "%02d:%04.1f" % [int(t / 60.0), fmod(t, 60.0)]


# ---------------------------------------------------------------- défis du jour / de la semaine

func challenge_objective_text(obj: Dictionary) -> String:
	match String(obj.get("type", "")):
		"falls": return tr("au plus %d chutes") % int(obj["value"])
		"nofall": return tr("aucune chute")
		"coins": return tr("au moins %d pièces") % int(obj["value"])
		"time": return tr("en moins de %s") % format_time(float(obj["value"]))
	return ""


## kind : "daily" ou "weekly". Même résultat pour tout le monde le même jour / la même semaine.
func challenge_def(kind: String) -> Dictionary:
	var days := int(Time.get_unix_time_from_system() / 86400.0)
	var cid := days if kind == "daily" else int(days / 7)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([cid, kind, 99])
	var pool := ["speed", "no_double", "mirror", "ice", "wind", "crumble", "fog", "lava", "timer", "invert"]
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var n := 2 if kind == "daily" else 3
	var forced := {"gravity": rng.randi() % 3, "length": 0 if kind == "daily" else 1, "difficulty": 1 if kind == "daily" else 2}
	for k in n:
		forced[pool[k]] = true
	var objectives := [
		{"type": "falls", "value": 4 if kind == "daily" else 6},
		{"type": "coins", "value": 8 if kind == "daily" else 10},
		{"type": "time", "value": 600.0 if kind == "daily" else 900.0},
		{"type": "falls", "value": 2 if kind == "daily" else 3},
	]
	var obj: Dictionary = objectives[rng.randi() % objectives.size()]
	return {
		"kind": kind,
		"key": ("d%d" if kind == "daily" else "w%d") % cid,
		"seed": daily_seed() if kind == "daily" else (cid * 7919) % 900000 + 100000,
		"mode": "quick",
		"mods": forced,
		"objective": obj,
		"reward": 30 if kind == "daily" else 100,
		"done": challenges_done.has(("d%d" if kind == "daily" else "w%d") % cid),
	}


func start_challenge(kind: String) -> void:
	var c := challenge_def(kind)
	if mods_backup.is_empty():
		mods_backup = mods.duplicate(true)
	reset_mods(false)
	for k in c["mods"]:
		mods[k] = c["mods"][k]
	start_run(int(c["seed"]), String(c["mode"]), [], false, kind == "daily")
	run["challenge"] = c["key"]
	run["objective"] = c["objective"]
	run["reward"] = c["reward"]
	run["challenge_kind"] = kind


func challenge_mod_text(c: Dictionary) -> String:
	var saved := mods
	mods = {"gravity": 1, "length": 0, "difficulty": 1}
	for t in TOGGLES:
		mods[t[0]] = false
	for k in c["mods"]:
		mods[k] = c["mods"][k]
	var s := mod_summary()
	mods = saved
	return s


# ---------------------------------------------------------------- codes de partage

## Code court qui décrit une run : mode, seed, modificateurs. Ex. : DR1-Q-482913-101-1A3
func share_code(mode: String, seed_value: int, worlds: Array = []) -> String:
	var m := "A"
	match mode:
		"quick": m = "Q"
		"endless": m = "E"
		"free": m = "F%d" % (int(worlds[0]) if not worlds.is_empty() else 0)
	var bits := 0
	for i in TOGGLES.size():
		if mods[TOGGLES[i][0]]:
			bits |= (1 << i)
	return "DR1-%s-%d-%d%d%d-%X" % [m, seed_value, int(mods["gravity"]), int(mods["length"]), int(mods["difficulty"]), bits]


## Lit un code de partage, applique ses modificateurs et retourne {mode, seed, worlds}, ou {} s'il est invalide.
func apply_share_code(code: String) -> Dictionary:
	var parts := code.strip_edges().to_upper().split("-")
	if parts.size() != 5 or parts[0] != "DR1":
		return {}
	var mode := ""
	var worlds: Array = []
	var m: String = parts[1]
	if m == "A": mode = "adventure"
	elif m == "Q": mode = "quick"
	elif m == "E": mode = "endless"
	elif m.begins_with("F") and m.substr(1).is_valid_int():
		mode = "free"
		worlds = [clampi(int(m.substr(1)), 0, LevelData.WORLD_COUNT - 1)]
	else:
		return {}
	if not parts[2].is_valid_int():
		return {}
	var dig: String = parts[3]
	if dig.length() != 3 or not dig.is_valid_int():
		return {}
	var g := int(dig[0])
	var l := int(dig[1])
	var d := int(dig[2])
	if g > 2 or l > 3 or d > 2 or not parts[4].is_valid_hex_number():
		return {}
	var bits := parts[4].hex_to_int()
	reset_mods(false)
	mods["gravity"] = g
	mods["length"] = l
	mods["difficulty"] = d
	for i in TOGGLES.size():
		mods[TOGGLES[i][0]] = (bits & (1 << i)) != 0
	save_game()
	return {"mode": mode, "seed": int(parts[2]), "worlds": worlds}


# ---------------------------------------------------------------- fantômes

func ghost_key(seed_value: int, world: int, stage: int) -> String:
	return "%d_%d_%d_%d_%d_%d" % [seed_value, world, stage, int(mods["length"]), int(mods["difficulty"]), 1 if mods["mirror"] else 0]


func _load_ghosts() -> void:
	if _ghosts_loaded:
		return
	_ghosts_loaded = true
	if FileAccess.file_exists(GHOST_PATH):
		var f := FileAccess.open(GHOST_PATH, FileAccess.READ)
		if f:
			var v = f.get_var()
			if v is Dictionary:
				_ghosts = v


func get_ghost(key: String) -> Dictionary:
	_load_ghosts()
	return _ghosts.get(key, {})


## Enregistre le fantôme s'il bat le précédent. Retourne vrai si c'est un nouveau record.
func save_ghost(key: String, time_s: float, data: PackedFloat32Array) -> bool:
	_load_ghosts()
	if _ghosts.has(key) and float((_ghosts[key] as Dictionary)["time"]) <= time_s:
		return false
	_ghosts.erase(key)
	_ghosts[key] = {"time": time_s, "data": data}
	while _ghosts.size() > 60:
		_ghosts.erase(_ghosts.keys()[0]) # plus ancien d'abord (ordre d'insertion)
	var f := FileAccess.open(GHOST_PATH, FileAccess.WRITE)
	if f:
		f.store_var(_ghosts)
	return true


# ---------------------------------------------------------------- sauvegarde

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "records", records)
	cfg.set_value("progress", "stats", stats)
	cfg.set_value("progress", "achievements", achievements)
	cfg.set_value("progress", "leaderboard", leaderboard)
	cfg.set_value("progress", "challenges_done", challenges_done)
	cfg.set_value("mods", "all", mods_backup if not mods_backup.is_empty() else mods)
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
	var lb: Dictionary = cfg.get_value("progress", "leaderboard", {})
	for k in lb:
		if leaderboard.has(k):
			leaderboard[k] = lb[k]
	challenges_done = cfg.get_value("progress", "challenges_done", {})
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
		_jingle_player.volume_db = linear_to_db(maxf(float(options["music"]), 0.0001))
	if not is_touch_device():
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if options["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)
	if get_tree().root.theme:
		get_tree().root.theme.default_font_size = int(22 * float(options["text_scale"]))
	apply_language()
	apply_keymap()


func _setup_audio() -> void:
	sounds = Sfx.build_all()
	# des fichiers dans audio/sfx/ remplacent les sons synthétisés
	for n in sounds.keys():
		var found := _find_audio("res://audio/sfx/", String(n))
		if found != "":
			sounds[n] = load(found)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	_jingle_player = AudioStreamPlayer.new()
	add_child(_jingle_player)


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


## Cherche un fichier audio par nom : accepte .ogg, .wav, .mp3 et les doubles extensions (jump.ogg.wav),
## ainsi que l'orthographe « loose » pour « lose ».
func _find_audio(dir: String, file_name: String) -> String:
	var names := [file_name]
	if file_name == "lose":
		names.append("loose")
	for n in names:
		for ext in ["ogg", "wav", "mp3", "ogg.wav", "wav.wav", "ogg.mp3", "mp3.mp3"]:
			var p := "%s%s.%s" % [dir, n, ext]
			if ResourceLoader.exists(p):
				return p
	return ""


func _load_music_file(file_name: String, looped: bool = true) -> AudioStream:
	var found := _find_audio("res://audio/music/", file_name)
	if found == "":
		found = _find_audio("res://audio/sfx/", file_name) if file_name == "lose" else ""
	if found != "":
		var p := found
		if true:
			var s: AudioStream = load(p)
			if not looped:
				return s
			if s is AudioStreamOggVorbis:
				(s as AudioStreamOggVorbis).loop = true
			elif s is AudioStreamMP3:
				(s as AudioStreamMP3).loop = true
			elif s is AudioStreamWAV and (s as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED:
				(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			return s
	return null


func _play_stream(key: String, s: AudioStream) -> void:
	_music_key = key
	_music_player.stream = s
	_music_player.volume_db = linear_to_db(maxf(float(options["music"]), 0.0001))
	_music_player.play()


## Musique d'un monde : fichier audio/music/world_XX_*.ogg s'il existe, sinon musique synthétisée.
func play_music(theme_idx: int) -> void:
	var key := "world_%d" % theme_idx
	if key == _music_key and _music_player.playing:
		return
	var s := _load_music_file(MUSIC_FILES[clampi(theme_idx, 0, MUSIC_FILES.size() - 1)])
	_play_stream(key, s if s else Sfx.music(theme_idx))


## Musique du menu ("menu") ou des écrans d'histoire ("story") : seulement si le fichier existe.
func play_ambient(file_name: String) -> void:
	if file_name == _music_key and _music_player.playing:
		return
	var s := _load_music_file(file_name)
	if s:
		_play_stream(file_name, s)
	else:
		stop_music()


## Jingle de fin ("win", "lose", "run_complete") : fichier audio/music/<nom>.ogg ou son synthétisé.
func play_jingle(jingle_name: String) -> void:
	var s := _load_music_file(jingle_name, false)
	if s:
		_jingle_player.stream = s
		_jingle_player.volume_db = linear_to_db(maxf(float(options["music"]), 0.0001))
		_jingle_player.play()
	else:
		play_sfx(jingle_name)


func stop_music() -> void:
	_music_key = ""
	_music_player.stop()


# ---------------------------------------------------------------- langue

func _setup_translations() -> void:
	for t in Translations.build():
		TranslationServer.add_translation(t)


func apply_language() -> void:
	var lang := String(options["language"])
	if lang == "auto":
		lang = "fr" if OS.get_locale_language() == "fr" else "en"
	TranslationServer.set_locale(lang)


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


## Remplace la première touche clavier d'une action (les flèches et la manette restent actives).
func set_key(action: String, physical_keycode: int) -> void:
	var done := false
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and not done:
			InputMap.action_erase_event(action, e)
			var ne := InputEventKey.new()
			ne.physical_keycode = physical_keycode
			InputMap.action_add_event(action, ne)
			done = true
	(options["keymap"] as Dictionary)[action] = physical_keycode


func key_name(action: String) -> String:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var pk: int = (e as InputEventKey).physical_keycode
			var kc := DisplayServer.keyboard_get_keycode_from_physical(pk)
			return OS.get_keycode_string(kc if kc != KEY_NONE else pk)
	return "—"


func apply_keymap() -> void:
	var km: Dictionary = options["keymap"]
	for action in km:
		if InputMap.has_action(String(action)):
			set_key(String(action), int(km[action]))


func reset_keymap() -> void:
	options["keymap"] = {}
	for action in DEFAULT_KEYS:
		set_key(String(action), int(DEFAULT_KEYS[action]))
	options["keymap"] = {}


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

extends SceneTree
## Test de fumée complet de la 3.0.0.
## Usage : godot --headless --path . --script tests/smoke.gd
## Code de sortie 0 si tout passe, 1 sinon.

const Gen = preload("res://scripts/generator.gd")
const LevelData = preload("res://scripts/level_data.gd")
const Achievements = preload("res://scripts/achievements.gd")

var g
var failures := 0


func check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		print("  FAIL ", msg)
		failures += 1


func _initialize() -> void:
	await process_frame
	await process_frame
	g = root.get_node("Global")
	g.reset_mods(false)
	g.reset_stats()

	print("== Générateur : 12 mondes x 4 longueurs x 3 difficultés x 8 seeds")
	var kinds := {}
	var bad := 0
	var det := true
	for w in 12:
		for li in 4:
			for dsel in 3:
				for sd in 8:
					var d: Dictionary = Gen.generate(sd * 31 + 7, w, 0, g.LENGTH_FACTORS[li], dsel)
					var expect := mini(int((9.0 + clampf(float(LevelData.get_themes()[w]["difficulty"]) + [-1.5, 0.0, 1.5][dsel], 0.5, 11.0) * 1.8) * g.LENGTH_FACTORS[li]), 90)
					if d["steps"].size() != expect:
						bad += 1
					for s in d["steps"]:
						kinds[s[5]] = int(kinds.get(s[5], 0)) + 1
						if float(s[0]) > 4.65 or float(s[0]) < 1.0:
							bad += 1
					if sd == 0 and str(Gen.generate(7, w, 0, g.LENGTH_FACTORS[li], dsel)) != str(d):
						det = false
	check(bad == 0, "comptes et écarts valides (anomalies : %d)" % bad)
	check(det, "génération déterministe")
	print("     types de plateformes : ", kinds)
	for k in ["n", "m", "f", "c", "b", "s", "k", "v", "o", "l"]:
		check(kinds.has(k), "type '%s' généré" % k)
	var d_easy: Dictionary = Gen.generate(5, 0, 0, 1.0, 1)
	var d_hard: Dictionary = Gen.generate(5, 11, 0, 1.0, 1)
	check(d_hard["steps"].size() > d_easy["steps"].size(), "le monde 12 est plus long que le monde 1")
	var d_long: Dictionary = Gen.generate(5, 4, 0, 3.0, 1)
	var d_norm: Dictionary = Gen.generate(5, 4, 0, 1.0, 1)
	check(d_long["steps"].size() >= 2.5 * d_norm["steps"].size(), "le modificateur Longueur allonge le niveau")

	print("== Les 12 mondes se construisent (tous modificateurs, Marathon)")
	g.mods["gravity"] = 0
	g.mods["length"] = 3
	g.mods["difficulty"] = 2
	for t in g.TOGGLES:
		g.mods[t[0]] = true
	g.mods["hardcore"] = false
	for w in 12:
		g.reset_run(1000 + w)
		g.run["stages"] = [w]
		g.run["mode"] = "free"
		var t0 := Time.get_ticks_msec()
		var lv = load("res://scenes/level.tscn").instantiate()
		root.add_child(lv)
		for f in 20:
			await physics_frame
		var ms := Time.get_ticks_msec() - t0
		check(lv.state == "play" and lv.platforms.size() > 40, "monde %d (%s) : %d plateformes, %d ms" % [w + 1, lv.data["name"], lv.platforms.size(), ms])
		lv.player.global_position.y = lv.kill_y - 1
		for f in 3:
			await physics_frame
		check(lv.deaths == 1, "  chute -> réapparition")
		lv._toggle_pause()
		lv._toggle_pause()
		lv._win()
		check(lv.state == "won", "  victoire")
		root.remove_child(lv)
		lv.free()

	print("== Runs complètes")
	g.reset_mods(false)
	g.reset_stats()
	g.start_run(5, "adventure")
	await process_frame
	await process_frame
	check(g.stage_total() == 12, "Aventure = 12 étapes")
	for st in 12:
		g.stage_cleared({"time": 50.0, "score": 2000, "coins": 3, "deaths": 1})
		await process_frame
		await process_frame
	check(not g.run["active"] and g.records.has("adventure"), "Aventure terminée et record enregistré")
	check(int(g.run["score"]) == 12 * 2000 + 1000, "score Aventure = 12 x 2000 + bonus (%d)" % int(g.run["score"]))

	g.start_run(9, "quick")
	await process_frame
	var qw: Array = g.run["stages"]
	check(qw.size() == 5 and qw[0] < 2 and qw[4] >= 9, "Run éclair : 5 mondes de difficulté croissante %s" % str(qw))
	check(str(g.quick_worlds(9)) == str(g.quick_worlds(9)), "Run éclair déterministe")
	for st in 5:
		g.stage_cleared({"time": 40.0, "score": 1500, "coins": 2, "deaths": 0})
		await process_frame
		await process_frame
	check(g.records.has("quick"), "Run éclair terminée")

	g.start_run(11, "free", [6])
	await process_frame
	await process_frame
	check(g.stage_total() == 1 and g.current_theme() == 6, "Monde libre = 1 monde")
	g.stage_cleared({"time": 30.0, "score": 900, "coins": 1, "deaths": 0})
	await process_frame
	await process_frame
	check(g.records.has("world_6"), "record du monde libre")

	print("== Succès, apparences, sauvegarde")
	check(g.achievements.has("adventure") and g.achievements.has("quick_run"), "succès de run débloqués")
	var got: Array = Achievements.evaluate_stage(g, {"time": 10.0, "par": 100.0, "deaths": 0, "coins": 4, "coins_total": 4, "length": 3, "mods": 5, "hardcore": true, "expert": true, "boost": true, "wing": true})
	check(got.has("no_fall") and got.has("all_coins") and got.has("speedy") and got.has("marathon") and got.has("chaos") and got.has("iron_heart") and got.has("expert") and got.has("power"), "succès d'étape (%d débloqués)" % got.size())
	g.stats["coins"] = 700
	check(g.unlocked_skins().size() == 8, "8 apparences à 700 pièces")
	g.options["skin"] = "rainbow"
	check(g.current_skin()["id"] == "rainbow", "apparence arc-en-ciel choisie")
	g.save_game()
	var saved_coins: int = g.stats["coins"]
	g.reset_stats()
	g.load_game()
	check(int(g.stats["coins"]) == saved_coins and g.records.has("adventure") and g.achievements.size() > 5, "sauvegarde / chargement")

	print("== Menus")
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	for p in ["main", "run", "worlds", "mods", "options", "stats", "skins", "story", "help"]:
		menu._show(p)
		await process_frame
	check(true, "9 pages du menu construites")
	root.remove_child(menu)
	menu.free()

	print("== Commandes tactiles et manette")
	g.reset_mods(false)
	g.options["touch"] = 1
	g.reset_run(321)
	g.run["stages"] = [0]
	g.run["mode"] = "free"
	var lv2 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv2)
	for f in 20:
		await physics_frame
	check(lv2.touch != null, "contrôles tactiles créés")
	var tc = lv2.touch
	var origin := Vector2(200, 560)
	tc._input(_touch(0, origin, true))
	tc._input(_drag(0, origin + Vector2(0, -80), Vector2(0, -80)))
	var z0: float = lv2.player.global_position.z
	for f in 30:
		await physics_frame
	check(Input.is_action_pressed("forward") and lv2.player.global_position.z < z0 - 1.0, "joystick vers le haut = avance (z %.1f -> %.1f)" % [z0, lv2.player.global_position.z])
	tc._input(_touch(0, origin, false))
	check(not Input.is_action_pressed("forward"), "relâcher le joystick arrête le mouvement")
	var jc: Vector2 = tc._jump_center()
	tc._input(_touch(1, jc, true))
	check(Input.is_action_pressed("jump"), "bouton de saut appuyé")
	tc._input(_touch(1, jc, false))
	var yaw0: float = lv2.player.yaw
	tc._input(_touch(2, Vector2(900, 300), true))
	tc._input(_drag(2, Vector2(940, 300), Vector2(40, 0)))
	check(absf(lv2.player.yaw - yaw0) > 0.05, "glisser à droite tourne la caméra")
	tc._input(_touch(2, Vector2(940, 300), false))
	var paused := [false]
	tc.pause_pressed.connect(func(): paused[0] = true)
	tc._input(_touch(3, tc._pause_center(), true))
	check(paused[0], "bouton pause tactile")
	tc._input(_touch(3, tc._pause_center(), false))
	check(lv2.state == "paused", "le bouton pause met le jeu en pause")
	lv2._resume()
	var ev := InputEventJoypadMotion.new()
	ev.axis = JOY_AXIS_RIGHT_X
	ev.axis_value = 1.0
	Input.parse_input_event(ev)
	var yaw1: float = lv2.player.yaw
	for f in 10:
		await physics_frame
	check(absf(lv2.player.yaw - yaw1) > 0.01, "stick droit de la manette tourne la caméra")
	ev.axis_value = 0.0
	Input.parse_input_event(ev)
	root.remove_child(lv2)
	lv2.free()
	g.options["touch"] = 0

	print("== Bonus et nouvelles plateformes")
	g.reset_run(77)
	g.run["stages"] = [6]
	g.run["mode"] = "free"
	var lv3 = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv3)
	for f in 10:
		await physics_frame
	var seen := {}
	for p in lv3.platforms:
		seen[p.kind] = true
	check(seen.has("v") or seen.has("o") or seen.has("l") or seen.has("k"), "monde 7 contient des plateformes spéciales %s" % str(seen.keys()))
	lv3.player.add_effect("boost")
	lv3.player.add_effect("wing")
	check(lv3.player.boost_t > 0.0 and lv3.player.wing_t > 0.0 and lv3.player.air_jumps >= 1, "bonus boost et ailes actifs")
	root.remove_child(lv3)
	lv3.free()

	g.reset_mods(false)
	g.reset_stats()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(g.SAVE_PATH))
	print("\nRÉSULTAT : ", "TOUT PASSE" if failures == 0 else "%d ÉCHEC(S)" % failures)
	quit(1 if failures > 0 else 0)


func _touch(idx: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = pos
	e.pressed = pressed
	return e


func _drag(idx: int, pos: Vector2, rel: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = idx
	e.position = pos
	e.relative = rel
	return e

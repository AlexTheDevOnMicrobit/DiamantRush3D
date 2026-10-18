extends SceneTree
## Test de fumée : générateur (300 seeds), 5 étapes avec TOUS les modificateurs, run complète.
## Usage : godot --headless --path . --script tests/smoke.gd
const Gen = preload("res://scripts/generator.gd")
func _initialize():
	await process_frame
	await process_frame
	var g = root.get_node("Global")
	# 1) generator sur 300 seeds
	var maxgap := 0.0; var fb := 0; var tot := 0; var kinds := {}
	for sd in 300:
		for st in 5:
			var d = Gen.generate(sd * 7 + 1, st)
			if d["steps"].size() != 13 + st * 3: print("BAD COUNT ", sd, " ", st, " ", d["steps"].size())
			for s in d["steps"]:
				maxgap = maxf(maxgap, s[0]); tot += 1
				kinds[s[5]] = kinds.get(s[5], 0) + 1
				if s[0] == 3.0 and s[3] == 4.0 and s[4] == 4.0 and s[5] == "n": fb += 1
	print("max gap ", maxgap, " fallbacks ", fb, "/", tot, " kinds ", kinds)
	# determinisme
	print("deterministe: ", str(Gen.generate(42, 2)) == str(Gen.generate(42, 2)))
	# 2) niveaux avec tous les modificateurs
	g.mods["gravity"] = 0
	for t in g.TOGGLES: g.mods[t[0]] = true
	g.mods["hardcore"] = false
	for st in 5:
		g.reset_run(777); g.run["stage"] = st
		var lv = load("res://scenes/level.tscn").instantiate()
		root.add_child(lv)
		for f in 150: await physics_frame
		print("stage ", st, " ok coins=", lv.coins_total, " state=", lv.state, " player_y=", snappedf(lv.player.global_position.y, 0.1), " lava=", snappedf(lv.lava_y, 0.01))
		print('  coin sample, lava_mesh=', lv.lava_mesh != null, ' wind=', lv.player.wind_vec, ' platforms=', lv.platform_tops.size())
		lv.player.global_position.y = lv.kill_y - 1
		for f in 3: await physics_frame
		print("  deaths=", lv.deaths)
		lv._toggle_pause(); lv._toggle_pause()
		lv._win()
		print("  win ", lv.state)
		root.remove_child(lv); lv.free()
	# 3) run complete via Global
	g.reset_mods(false)
	g.start_run(5)
	await process_frame; await process_frame
	print("scene: ", current_scene.name if current_scene else "none", " stage=", g.run["stage"])
	for st in 5:
		g.stage_cleared(50.0, 2000, 3, 1)
		await process_frame; await process_frame
		print(" apres stage ", st, " scene=", current_scene.name if current_scene else "none", " run_stage=", g.run["stage"], " active=", g.run["active"])
	print("score=", g.run["score"], " best=", g.best_run_score, " runs=", g.runs_completed)
	quit()

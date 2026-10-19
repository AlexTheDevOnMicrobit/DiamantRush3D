extends SceneTree
## Génère des captures d'écran du menu et de chacun des 12 mondes pour les pages de boutique.
## Ouvre une fenêtre quelques secondes (il faut un rendu réel, donc PAS en --headless) :
##   godot --path . --script tools/screenshots.gd -- 1920 1080
## Les images PNG sont écrites dans store/screenshots/.

func _initialize() -> void:
	await process_frame
	await process_frame
	var g = root.get_node("Global")
	var args := OS.get_cmdline_user_args()
	var w := int(args[0]) if args.size() >= 2 else 1920
	var h := int(args[1]) if args.size() >= 2 else 1080
	DisplayServer.window_set_size(Vector2i(w, h))
	var dir := ProjectSettings.globalize_path("res://store/screenshots")
	DirAccess.make_dir_recursive_absolute(dir)
	g.options["language"] = "en"
	g.apply_language()

	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	for i in 30:
		await process_frame
	_shot(dir + "/00_menu.png")
	root.remove_child(menu)
	menu.free()

	for world in 12:
		g.reset_mods(false)
		g.reset_run(2026 + world)
		g.run["stages"] = [world]
		g.run["mode"] = "free"
		var lv = load("res://scenes/level.tscn").instantiate()
		root.add_child(lv)
		for i in 90:
			await physics_frame
		# Lumi sur un des premiers checkpoints, caméra légèrement relevée
		if lv.platforms.size() > 4:
			lv.player.teleport(lv.platform_tops[3] + Vector3(0, 0.4, 0))
		lv.player.pitch = 0.45
		for i in 60:
			await physics_frame
		_shot(dir + "/world_%02d.png" % (world + 1))
		root.remove_child(lv)
		lv.free()
	print("Captures écrites dans ", dir)
	quit()


func _shot(path: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(path)
	print("  ", path)

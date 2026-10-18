extends Control
## Menu principal : run, modificateurs, options, histoire, commandes.

const UI = preload("res://scripts/ui.gd")
const Models = preload("res://scripts/models.gd")
const Story = preload("res://scripts/story.gd")

var pages: Dictionary = {}
var gem: Node3D
var drifters: Array[MeshInstance3D] = []
var mult_label: Label
var seed_edit: LineEdit
var _t := 0.0


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.stop_music()
	_build_background()
	for p in ["main", "run", "mods", "options", "story", "help"]:
		var c := CenterContainer.new()
		add_child(c)
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pages[p] = c
	_build_story()
	_build_help()
	_show("main")


func _process(delta: float) -> void:
	_t += delta
	gem.rotation.y += delta * 0.8
	gem.position.y = sin(_t * 1.5) * 0.15
	for i in drifters.size():
		drifters[i].rotation += Vector3(0.3, 0.5, 0.2) * delta * (1.0 + i * 0.1)


func _show(page_name: String) -> void:
	match page_name:
		"main": _build_main()
		"run": _build_run()
		"mods": _build_mods()
		"options": _build_options()
	for k in pages:
		pages[k].visible = (k == page_name)


func _clear(page: Control) -> VBoxContainer:
	for c in page.get_children():
		c.queue_free()
	var vb := UI.vbox(10)
	page.add_child(vb)
	return vb


func _centered(btn: Control) -> CenterContainer:
	var row := CenterContainer.new()
	row.add_child(btn)
	return row


# ---------------------------------------------------------------- fond 3D

func _build_background() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	add_child(svc)
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	svc.add_child(vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.06, 0.15)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.5, 0.8)
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.3, 5.0)
	cam.fov = 50.0
	vp.add_child(cam)

	var light := OmniLight3D.new()
	light.position = Vector3(2, 3, 4)
	light.light_energy = 3.0
	light.omni_range = 20.0
	vp.add_child(light)

	gem = Node3D.new()
	vp.add_child(gem)
	var mi := MeshInstance3D.new()
	mi.mesh = Models.diamond_mesh()
	mi.scale = Vector3.ONE * 1.6
	var mat := Models.material(Color(0.3, 0.95, 1.0), 1.0, 0.6, 0.1)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	gem.add_child(mi)
	gem.position.x = 3.6

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var d := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var s := rng.randf_range(0.2, 0.6)
		bm.size = Vector3(s, s, s)
		d.mesh = bm
		d.material_override = Models.material(Color.from_hsv(rng.randf(), 0.5, 0.95))
		d.position = Vector3(rng.randf_range(-6, 6), rng.randf_range(-3, 3), rng.randf_range(-6, 0))
		vp.add_child(d)
		drifters.append(d)


# ---------------------------------------------------------------- pages

func _build_main() -> void:
	var vb := _clear(pages["main"])
	vb.add_child(UI.label("DIAMANT RUSH", 76, Color(0.5, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.label("Récupère les 5 éclats du Grand Diamant   •   v%s" % Global.VERSION, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var rec := "Pas encore de run terminée"
	if Global.runs_completed > 0:
		rec = "Meilleure run : %d pts en %s   •   %d run(s) terminée(s)" % [Global.best_run_score, Global.format_time(Global.best_run_time), Global.runs_completed]
	elif Global.best_stage > 0:
		rec = "Étape la plus loin atteinte : %d/%d" % [Global.best_stage, Global.STAGE_COUNT]
	vb.add_child(UI.label(rec, 18, Color(1, 0.9, 0.5), HORIZONTAL_ALIGNMENT_CENTER))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 20)
	vb.add_child(gap)
	vb.add_child(_centered(UI.button("Nouvelle run", _show.bind("run"))))
	vb.add_child(_centered(UI.button("Modificateurs", _show.bind("mods"))))
	vb.add_child(_centered(UI.button("Options", _show.bind("options"))))
	vb.add_child(_centered(UI.button("Histoire", _show.bind("story"))))
	vb.add_child(_centered(UI.button("Commandes", _show.bind("help"))))
	vb.add_child(_centered(UI.button("Quitter", func(): get_tree().quit())))


func _build_run() -> void:
	var vb := _clear(pages["run"])
	vb.add_child(UI.label("Nouvelle run", 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.label("5 étapes générées au hasard, une par royaume. Une même seed donne toujours les mêmes parcours.", 18, Color(0.85, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.label("Modificateurs : " + Global.mod_summary(), 20, Color(0.7, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(_centered(UI.button("Run aléatoire", _start_random, Vector2(420, 56))))
	vb.add_child(_centered(UI.button("Run du jour (seed %d)" % Global.daily_seed(), _start_daily, Vector2(420, 56))))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	seed_edit = LineEdit.new()
	seed_edit.placeholder_text = "Seed (nombre ou mot)"
	seed_edit.custom_minimum_size = Vector2(240, 54)
	row.add_child(seed_edit)
	row.add_child(UI.button("Lancer", _start_custom, Vector2(166, 54)))
	vb.add_child(row)

	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 12)
	row2.add_child(UI.button("Modificateurs", _show.bind("mods"), Vector2(204, 54)))
	row2.add_child(UI.button("Retour", _show.bind("main"), Vector2(204, 54)))
	vb.add_child(row2)


func _start_random() -> void:
	Global.start_run(randi() % 900000 + 100000)


func _start_daily() -> void:
	Global.start_run(Global.daily_seed())


func _start_custom() -> void:
	var t := seed_edit.text.strip_edges()
	if t == "":
		_start_random()
		return
	Global.start_run(int(t) if t.is_valid_int() else absi(hash(t)) % 900000 + 100000)


func _build_mods() -> void:
	var vb := _clear(pages["mods"])
	vb.add_child(UI.label("Modificateurs", 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(UI.label("Change les règles pour rejouer autrement : plus c'est dur, plus le score est multiplié.", 18, Color(0.85, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER))

	var grav_row := HBoxContainer.new()
	grav_row.add_theme_constant_override("separation", 16)
	grav_row.add_child(UI.label("Gravité", 22))
	var opt := OptionButton.new()
	opt.add_item("Lunaire (longs sauts flottants)", 0)
	opt.add_item("Normale", 1)
	opt.add_item("Lourde (chute rapide, sauts courts)", 2)
	opt.selected = int(Global.mods["gravity"])
	opt.item_selected.connect(_on_gravity)
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grav_row.add_child(opt)
	vb.add_child(grav_row)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	vb.add_child(grid)
	for t in Global.TOGGLES:
		var cb := CheckButton.new()
		cb.text = String(t[1])
		cb.button_pressed = bool(Global.mods[t[0]])
		cb.toggled.connect(_on_toggle.bind(String(t[0])))
		grid.add_child(cb)

	mult_label = UI.label("", 26, Color.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	vb.add_child(mult_label)
	_update_mult()

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.button("Aléatoire", _randomize, Vector2(180, 54)))
	row.add_child(UI.button("Réinitialiser", _reset_mods, Vector2(180, 54)))
	row.add_child(UI.button("Retour", _show.bind("main"), Vector2(180, 54)))
	vb.add_child(row)


func _on_gravity(idx: int) -> void:
	Global.mods["gravity"] = idx
	Global.save_game()
	_update_mult()


func _on_toggle(on: bool, key: String) -> void:
	Global.mods[key] = on
	Global.save_game()
	_update_mult()


func _update_mult() -> void:
	mult_label.text = "Multiplicateur de score : x%.2f" % Global.multiplier()


func _randomize() -> void:
	Global.randomize_mods()
	_build_mods()


func _reset_mods() -> void:
	Global.reset_mods()
	_build_mods()


func _build_options() -> void:
	var vb := _clear(pages["options"])
	vb.add_child(UI.label("Options", 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	_slider(grid, "Volume général", "master", 0.0, 1.0, 0.05)
	_slider(grid, "Musique", "music", 0.0, 1.0, 0.05)
	_slider(grid, "Effets sonores", "sfx", 0.0, 1.0, 0.05)
	_slider(grid, "Sensibilité souris", "sens", 0.3, 3.0, 0.1)
	_slider(grid, "Champ de vision (FOV)", "fov", 60.0, 110.0, 1.0)
	for entry in [
		["invert_y", "Inverser l'axe vertical de la souris"],
		["fullscreen", "Plein écran"],
		["shadows", "Ombres (désactive si ça rame)"],
		["hint", "Afficher l'aide des touches en jeu"],
	]:
		var cb := CheckButton.new()
		cb.text = entry[1]
		cb.button_pressed = bool(Global.options[entry[0]])
		cb.toggled.connect(_on_option_toggle.bind(String(entry[0])))
		vb.add_child(cb)
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"))))


func _slider(grid: GridContainer, text: String, key: String, lo: float, hi: float, step: float) -> void:
	grid.add_child(UI.label(text, 22))
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Global.options[key])
	s.custom_minimum_size = Vector2(320, 30)
	s.value_changed.connect(_on_slider.bind(key))
	grid.add_child(s)


func _on_slider(v: float, key: String) -> void:
	Global.options[key] = v
	Global.apply_options()
	Global.save_game()
	if key == "sfx":
		Global.play_sfx("coin")


func _on_option_toggle(on: bool, key: String) -> void:
	Global.options[key] = on
	Global.apply_options()
	Global.save_game()


func _build_story() -> void:
	var vb := _clear(pages["story"])
	vb.add_child(UI.label(Story.INTRO_TITLE, 46, Color.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var l := UI.label(Story.INTRO, 22, Color.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(760, 0)
	vb.add_child(l)
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"))))


func _build_help() -> void:
	var vb := _clear(pages["help"])
	vb.add_child(UI.label("Commandes", 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	for l in [
		"Déplacement : WASD / ZQSD / flèches",
		"Sauter : Espace (appuie à nouveau en l'air : double saut)",
		"Caméra : souris",
		"Pause : Échap   •   Recommencer l'étape : R",
		"",
		"Dalles bleues : mobiles   •   Oranges : elles s'effondrent",
		"Bleu clair : checkpoint   •   Roses : trampolines   •   Barres rouges : à éviter",
		"Ramasse les pièces dorées et atteins le diamant !",
	]:
		vb.add_child(UI.label(l, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"))))

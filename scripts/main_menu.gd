extends Control
## Menu principal : runs, mondes, modificateurs, apparences, succès, options, histoire, commandes.

const UI = preload("res://scripts/ui.gd")
const Models = preload("res://scripts/models.gd")
const Story = preload("res://scripts/story.gd")
const LevelData = preload("res://scripts/level_data.gd")
const Achievements = preload("res://scripts/achievements.gd")

var pages: Dictionary = {}   # nom -> CenterContainer (contenu d'un ScrollContainer)
var page_roots: Dictionary = {}
var current_page := "main"
var gem: Node3D
var gem_mat: StandardMaterial3D
var drifters: Array[MeshInstance3D] = []
var mult_label: Label
var seed_edit: LineEdit
var reset_armed := false
var _t := 0.0


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.stop_music()
	_build_background()
	for p in ["main", "run", "worlds", "mods", "options", "stats", "skins", "story", "help"]:
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(sc)
		sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var c := CenterContainer.new()
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.add_child(c)
		pages[p] = c
		page_roots[p] = sc
	_build_story()
	_build_help()
	_show("main")


func _process(delta: float) -> void:
	_t += delta
	gem.rotation.y += delta * 0.8
	gem.position.y = sin(_t * 1.5) * 0.15
	for i in drifters.size():
		drifters[i].rotation += Vector3(0.3, 0.5, 0.2) * delta * (1.0 + i * 0.1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if current_page == "main":
			get_tree().quit()
		else:
			_show("main")


func _show(page_name: String) -> void:
	current_page = page_name
	reset_armed = false
	match page_name:
		"main": _build_main()
		"run": _build_run()
		"worlds": _build_worlds()
		"mods": _build_mods()
		"options": _build_options()
		"stats": _build_stats()
		"skins": _build_skins()
	for k in pages:
		page_roots[k].visible = (k == page_name)
	if page_roots.has(page_name):
		(page_roots[page_name] as ScrollContainer).scroll_vertical = 0


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


func _title(vb: VBoxContainer, text: String, sub: String = "") -> void:
	vb.add_child(UI.label(text, 46, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	if sub != "":
		var l := UI.label(sub, 18, Color(0.85, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(640, 0)
		vb.add_child(l)


# ---------------------------------------------------------------- fond 3D

func _build_background() -> void:
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	env.glow_enabled = Global.quality() >= 1
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
	gem_mat = Models.material(Color(0.3, 0.95, 1.0), 1.0, 0.6, 0.1)
	gem_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = gem_mat
	gem.add_child(mi)
	gem.position.x = 3.6

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var n: int = [6, 10, 14][Global.quality()]
	for i in n:
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
	vb.add_child(UI.label("Récupère les éclats du Grand Diamant   •   v%s" % Global.VERSION, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var rec := "Pas encore de run terminée"
	if Global.records.has("adventure"):
		var r: Dictionary = Global.records["adventure"]
		rec = "Meilleure Aventure : %d pts en %s" % [int(r["score"]), Global.format_time(float(r["time"]))]
	elif Global.records.has("quick"):
		var r2: Dictionary = Global.records["quick"]
		rec = "Meilleure Run éclair : %d pts en %s" % [int(r2["score"]), Global.format_time(float(r2["time"]))]
	vb.add_child(UI.label(rec, 18, Color(1, 0.9, 0.5), HORIZONTAL_ALIGNMENT_CENTER))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	vb.add_child(gap)
	vb.add_child(_centered(UI.button("Nouvelle run", _show.bind("run"))))
	vb.add_child(_centered(UI.button("Monde libre", _show.bind("worlds"))))
	vb.add_child(_centered(UI.button("Modificateurs", _show.bind("mods"))))
	vb.add_child(_centered(UI.button("Apparences de Lumi", _show.bind("skins"))))
	vb.add_child(_centered(UI.button("Succès et statistiques", _show.bind("stats"))))
	vb.add_child(_centered(UI.button("Options", _show.bind("options"))))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.add_child(UI.button("Histoire", _show.bind("story"), Vector2(110, 54)))
	row.add_child(UI.button("Commandes", _show.bind("help"), Vector2(130, 54)))
	row.add_child(UI.button("Quitter", func(): get_tree().quit(), Vector2(80, 54)))
	vb.add_child(row)
	gem_mat.albedo_color = Global.current_skin()["color"] if Global.current_skin()["id"] != "rainbow" else Color(0.3, 0.95, 1.0)
	gem_mat.emission = gem_mat.albedo_color


func _build_run() -> void:
	var vb := _clear(pages["run"])
	_title(vb, "Nouvelle run", "Les parcours sont générés au hasard : une même seed redonne toujours les mêmes mondes.")
	vb.add_child(UI.label("Modificateurs : " + Global.mod_summary(), 20, Color(0.7, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(_centered(UI.button("Aventure — 12 mondes, de plus en plus durs", _start.bind("adventure", 0), Vector2(560, 58))))
	vb.add_child(_centered(UI.button("Run éclair — 5 mondes tirés au sort", _start.bind("quick", 0), Vector2(560, 58))))
	vb.add_child(_centered(UI.button("Run du jour (seed %d) — éclair" % Global.daily_seed(), _start.bind("quick", Global.daily_seed()), Vector2(560, 58))))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	seed_edit = LineEdit.new()
	seed_edit.placeholder_text = "Seed (nombre ou mot)"
	seed_edit.custom_minimum_size = Vector2(240, 54)
	row.add_child(seed_edit)
	row.add_child(UI.button("Aventure", _start_custom.bind("adventure"), Vector2(150, 54)))
	row.add_child(UI.button("Éclair", _start_custom.bind("quick"), Vector2(150, 54)))
	vb.add_child(row)

	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 12)
	row2.add_child(UI.button("Modificateurs", _show.bind("mods"), Vector2(274, 54)))
	row2.add_child(UI.button("Retour", _show.bind("main"), Vector2(274, 54)))
	vb.add_child(row2)


func _random_seed() -> int:
	return randi() % 900000 + 100000


func _start(mode: String, seed_value: int) -> void:
	Global.start_run(seed_value if seed_value != 0 else _random_seed(), mode, [], false, seed_value != 0 and seed_value == Global.daily_seed())


func _start_custom(mode: String) -> void:
	var t := seed_edit.text.strip_edges()
	var s := _random_seed()
	if t != "":
		s = int(t) if t.is_valid_int() else absi(hash(t)) % 900000 + 100000
	Global.start_run(s, mode)


func _build_worlds() -> void:
	var vb := _clear(pages["worlds"])
	_title(vb, "Monde libre", "Entraîne-toi sur un monde précis. La difficulté dépend du monde (et de ton réglage Détendu / Normal / Expert).")
	vb.add_child(UI.label("Modificateurs : " + Global.mod_summary(), 18, Color(0.7, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	var themes := LevelData.get_themes()
	for i in themes.size():
		var th: Dictionary = themes[i]
		var text := "%d — %s   %s" % [i + 1, th["name"], LevelData.difficulty_stars(float(th["difficulty"]))]
		var key := "world_%d" % i
		if Global.records.has(key):
			text += "   •   %d pts" % int((Global.records[key] as Dictionary)["score"])
		vb.add_child(_centered(UI.button(text, _start_world.bind(i), Vector2(620, 54))))
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"), Vector2(620, 54))))


func _start_world(i: int) -> void:
	Global.start_run(_random_seed(), "free", [i])


func _option(vb_or_row: Control, items: Array, selected: int, cb: Callable) -> OptionButton:
	var opt := OptionButton.new()
	for i in items.size():
		opt.add_item(String(items[i]), i)
	opt.selected = selected
	opt.item_selected.connect(cb)
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.custom_minimum_size = Vector2(0, 46)
	vb_or_row.add_child(opt)
	return opt


func _opt_row(vb: VBoxContainer, label: String, items: Array, selected: int, cb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := UI.label(label, 22)
	l.custom_minimum_size = Vector2(150, 0)
	row.add_child(l)
	_option(row, items, selected, cb)
	vb.add_child(row)


func _build_mods() -> void:
	var vb := _clear(pages["mods"])
	_title(vb, "Modificateurs", "Change les règles pour rejouer autrement : plus c'est dur, plus le score est multiplié.")

	_opt_row(vb, "Gravité", ["Lunaire (longs sauts flottants)", "Normale", "Lourde (chute rapide, sauts courts)"], int(Global.mods["gravity"]), _on_mod_option.bind("gravity"))
	_opt_row(vb, "Longueur", Global.LENGTH_NAMES, int(Global.mods["length"]), _on_mod_option.bind("length"))
	_opt_row(vb, "Difficulté", Global.DIFFICULTY_NAMES, int(Global.mods["difficulty"]), _on_mod_option.bind("difficulty"))

	var grid := GridContainer.new()
	grid.columns = 1 if get_viewport_rect().size.x < 900 else 2
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


func _on_mod_option(idx: int, key: String) -> void:
	Global.mods[key] = idx
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
	_title(vb, "Options")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	_slider(grid, "Volume général", "master", 0.0, 1.0, 0.05)
	_slider(grid, "Musique", "music", 0.0, 1.0, 0.05)
	_slider(grid, "Effets sonores", "sfx", 0.0, 1.0, 0.05)
	_slider(grid, "Sensibilité caméra", "sens", 0.3, 3.0, 0.1)
	_slider(grid, "Champ de vision (FOV)", "fov", 60.0, 110.0, 1.0)
	_slider(grid, "Taille des commandes tactiles", "touch_scale", 0.7, 1.5, 0.05)
	_opt_row(vb, "Qualité", Global.QUALITY_NAMES, Global.quality(), _on_quality)
	_opt_row(vb, "Commandes tactiles", ["Automatique", "Toujours affichées", "Masquées"], int(Global.options["touch"]), _on_touch_mode)
	for entry in [
		["invert_y", "Inverser l'axe vertical de la caméra"],
		["fullscreen", "Plein écran"],
		["shadows", "Ombres (qualité moyenne ou élevée)"],
		["vibration", "Vibrations (mobile)"],
		["hint", "Afficher l'aide des touches en jeu"],
	]:
		var cb := CheckButton.new()
		cb.text = entry[1]
		cb.button_pressed = bool(Global.options[entry[0]])
		cb.toggled.connect(_on_option_toggle.bind(String(entry[0])))
		vb.add_child(cb)
	var danger := UI.button("Effacer la sauvegarde (records, succès, pièces)", _on_reset_progress, Vector2(560, 54))
	danger.name = "ResetBtn"
	vb.add_child(_centered(danger))
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"), Vector2(560, 54))))


func _on_reset_progress() -> void:
	var b := pages["options"].find_child("ResetBtn", true, false) as Button
	if not reset_armed:
		reset_armed = true
		if b:
			b.text = "Appuie encore pour confirmer l'effacement"
		return
	Global.reset_stats()
	Global.save_game()
	reset_armed = false
	_build_options()


func _slider(grid: GridContainer, text: String, key: String, lo: float, hi: float, step: float) -> void:
	grid.add_child(UI.label(text, 22))
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Global.options[key])
	s.custom_minimum_size = Vector2(320, 34)
	s.value_changed.connect(_on_slider.bind(key))
	grid.add_child(s)


func _on_slider(v: float, key: String) -> void:
	Global.options[key] = v
	Global.apply_options()
	Global.save_game()
	if key == "sfx":
		Global.play_sfx("coin")


func _on_quality(idx: int) -> void:
	Global.options["quality"] = idx
	Global.save_game()


func _on_touch_mode(idx: int) -> void:
	Global.options["touch"] = idx
	Global.save_game()


func _on_option_toggle(on: bool, key: String) -> void:
	Global.options[key] = on
	Global.apply_options()
	Global.save_game()


func _build_stats() -> void:
	var vb := _clear(pages["stats"])
	_title(vb, "Succès et statistiques")
	var st: Dictionary = Global.stats
	var lines := [
		"Temps de jeu : %s   •   Étapes terminées : %d   •   Runs terminées : %d" % [Global.format_time(float(st["playtime"])), int(st["stages"]), int(st["runs"])],
		"Pièces : %d   •   Sauts : %d   •   Chutes : %d   •   Mondes terminés : %d/12" % [int(st["coins"]), int(st["jumps"]), int(st["falls"]), (st["worlds"] as Array).size()],
	]
	for l in lines:
		var lb := UI.label(String(l), 18, Color(0.85, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.custom_minimum_size = Vector2(700, 0)
		vb.add_child(lb)
	var done := 0
	for d in Achievements.DEFS:
		var ok: bool = Global.achievements.has(d[0])
		if ok:
			done += 1
		var l2 := UI.label("%s %s — %s" % ["★" if ok else "☆", d[1], d[2]], 20, Color(1.0, 0.9, 0.4) if ok else Color(0.6, 0.62, 0.7))
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.custom_minimum_size = Vector2(700, 0)
		vb.add_child(l2)
	vb.add_child(UI.label("Succès débloqués : %d/%d" % [done, Achievements.DEFS.size()], 22, Color.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"))))


func _build_skins() -> void:
	var vb := _clear(pages["skins"])
	_title(vb, "Apparences de Lumi", "Ramasse des pièces pour débloquer de nouvelles couleurs. Pièces totales : %d" % int(Global.stats["coins"]))
	var cur := Global.current_skin()
	for s in Global.SKINS:
		var unlocked := int(Global.stats["coins"]) >= int(s["cost"])
		var text := String(s["name"])
		if not unlocked:
			text += "   (verrouillé : %d pièces)" % int(s["cost"])
		elif s["id"] == cur["id"]:
			text += "   ✔ choisie"
		var b := UI.button(text, _pick_skin.bind(String(s["id"])), Vector2(520, 54))
		b.disabled = not unlocked
		if unlocked and s["id"] != "rainbow":
			b.add_theme_color_override("font_color", Color(s["color"]).lightened(0.3))
		vb.add_child(_centered(b))
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"), Vector2(520, 54))))


func _pick_skin(id: String) -> void:
	Global.options["skin"] = id
	Global.save_game()
	var sk := Global.skin_by_id(id)
	Global.play_sfx("checkpoint")
	_build_skins()
	if gem_mat and id != "rainbow":
		gem_mat.albedo_color = sk["color"]
		gem_mat.emission = sk["color"]


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
		"Clavier : WASD / ZQSD / flèches pour bouger • Espace : sauter / double saut",
		"Souris : caméra • Échap : pause • R : recommencer l'étape",
		"Manette : stick gauche bouger • stick droit caméra • A sauter • Start pause",
		"Mobile : joystick à gauche, bouton SAUT à droite, glisse à droite pour la caméra",
		"",
		"Dalles bleues : mobiles • Oranges : elles s'effondrent • Violettes : clignotantes",
		"Grises avec chevrons : tapis roulants • Turquoise : orbitales • Jaunes : ascenseurs",
		"Roses : trampolines • Barres rouges : à éviter • Bleu clair : checkpoint",
		"Bonus flottants : flèche orange = vitesse • ailes = saut supplémentaire",
		"Ramasse les pièces dorées et atteins le diamant !",
	]:
		var lb := UI.label(l, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.custom_minimum_size = Vector2(760, 0)
		vb.add_child(lb)
	vb.add_child(_centered(UI.button("Retour", _show.bind("main"))))

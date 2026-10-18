extends Node3D
## Construit l'étape courante de la run (parcours généré), gère HUD, pause, victoire et défaite.

const Platform = preload("res://scripts/platform.gd")
const Pickup = preload("res://scripts/pickup.gd")
const PlayerScript = preload("res://scripts/player.gd")
const Overlay = preload("res://scripts/overlay.gd")
const UI = preload("res://scripts/ui.gd")
const LevelData = preload("res://scripts/level_data.gd")
const Generator = preload("res://scripts/generator.gd")
const Decor = preload("res://scripts/decor.gd")
const Fx = preload("res://scripts/fx.gd")
const Models = preload("res://scripts/models.gd")

const HEADINGS: Array[Vector3] = [
	Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
]

var data: Dictionary
var theme: Dictionary
var stage := 0
var player: CharacterBody3D
var checkpoint := Vector3(0, 0.3, 0)
var kill_y := -30.0
var lava_y := -9.0
var lava_mesh: MeshInstance3D
var coins_total := 0
var coins_got := 0
var deaths := 0
var time := 0.0
var state := "play" # play | paused | won | failed
var par := 100.0
var mirror := false
var platform_tops: Array = []
var platforms: Array = []

var overlay: CanvasLayer
var panel_nodes: Array[Node] = []
var lbl_time: Label
var lbl_coins: Label
var lbl_deaths: Label
var lbl_hint: Label
var lbl_wind: Label


func _ready() -> void:
	get_tree().paused = false
	stage = int(Global.run["stage"])
	data = Generator.generate(int(Global.run["seed"]), stage)
	theme = LevelData.get_themes()[stage]
	par = float(data["par"])
	mirror = Global.mods["mirror"]
	_build_environment()
	_build_course()
	_build_scenery()
	_build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Global.play_music(stage)


# ---------------------------------------------------------------- construction

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = theme["sky_top"]
	sky_mat.sky_horizon_color = theme["sky_horizon"]
	sky_mat.ground_horizon_color = theme["sky_horizon"]
	sky_mat.ground_bottom_color = Color(theme["sky_top"]).darkened(0.5)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = theme["sky_horizon"]
	env.fog_density = 0.045 if Global.mods["fog"] else float(theme["fog"])
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.ssao_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.shadow_enabled = bool(Global.options["shadows"])
	sun.directional_shadow_max_distance = 90.0
	if stage == 4:
		sun.light_energy = 0.6
	add_child(sun)


func _half(sz: Vector2, heading: int) -> float:
	return (sz.y if heading % 2 == 0 else sz.x) / 2.0


func _mx(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z) if mirror else v


func _make_platform(top: Vector3, sz: Vector2, kind: String, right: Vector3, idx: int) -> void:
	if kind == "n" and Global.mods["crumble"] and idx > 0:
		kind = "f"
	var p := Platform.new()
	p.kind = kind
	p.size = Vector3(sz.x, 1.0, sz.y)
	p.top_color = theme["top"]
	p.side_color = theme["side"]
	p.theme_idx = stage
	p.prop_seed = hash([Global.run["seed"], stage, idx])
	p.move_axis = _mx(right)
	p.level = self
	p.position = _mx(top) - Vector3(0, 0.5, 0)
	add_child(p)
	platforms.append(p)
	platform_tops.append(_mx(top))


func _make_pickup(pos: Vector3, kind: String) -> void:
	var pk := Pickup.new()
	pk.kind = kind
	pk.position = _mx(pos)
	pk.collected.connect(_on_pickup.bind(pk))
	add_child(pk)


func _build_course() -> void:
	var steps: Array = data["steps"]
	var pos := Vector3.ZERO # centre du dessus de la plateforme courante
	var heading := 0
	var prev_size := Vector2(8, 8)
	var min_y := 0.0
	_make_platform(pos, prev_size, "n", Vector3.RIGHT, 0)

	for i in steps.size():
		var s: Array = steps[i]
		var kind: String = s[5]
		var sz := Vector2(float(s[3]), float(s[4]))
		if s.size() > 6:
			heading = int(s[6])
		var f: Vector3 = HEADINGS[heading]
		var r: Vector3 = f.cross(Vector3.UP)
		pos += f * (_half(prev_size, heading) + float(s[0]) + _half(sz, heading))
		pos += r * float(s[2]) + Vector3(0, float(s[1]), 0)
		prev_size = sz
		min_y = minf(min_y, pos.y)
		_make_platform(pos, sz, kind, r, i + 1)

		if i == steps.size() - 1:
			_make_pickup(pos + Vector3(0, 1.5, 0), "diamond")
		elif i % 2 == 1 and kind in ["n", "c"]:
			_make_pickup(pos + Vector3(0, 1.3, 0), "coin")
			coins_total += 1

	kill_y = min_y - 18.0
	player = PlayerScript.new()
	player.position = Vector3(0, 0.3, 0)
	player.theme_idx = stage
	add_child(player)
	Fx.ambient(player, stage, theme["particle"])

	if Global.mods["lava"]:
		lava_mesh = MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1500, 1500)
		lava_mesh.mesh = pm
		lava_mesh.material_override = Models.material(Color(1.0, 0.3, 0.05), 1.8)
		add_child(lava_mesh)
		lava_mesh.position.y = lava_y


func _build_scenery() -> void:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for t in platform_tops:
		var v: Vector3 = t
		lo = Vector3(minf(lo.x, v.x), minf(lo.y, v.y), minf(lo.z, v.z))
		hi = Vector3(maxf(hi.x, v.x), maxf(hi.y, v.y), maxf(hi.z, v.z))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([Global.run["seed"], stage, 31337])
	var node := Node3D.new()
	add_child(node)
	Decor.scenery(node, stage, (lo + hi) * 0.5, (hi - lo) * 0.5, lo.y, platform_tops, rng)


func _build_ui() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(margin)
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var left := UI.vbox(2)
	top.add_child(left)
	left.add_child(UI.label("Étape %d/%d — %s" % [stage + 1, Global.STAGE_COUNT, data["name"]], 28, Color(1, 0.95, 0.6)))
	lbl_time = UI.label("00:00.0", 26)
	left.add_child(lbl_time)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var right := UI.vbox(2)
	top.add_child(right)
	lbl_coins = UI.label("", 26, Color(1, 0.85, 0.2), HORIZONTAL_ALIGNMENT_RIGHT)
	lbl_deaths = UI.label("", 22, Color(1, 0.6, 0.6), HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(lbl_coins)
	right.add_child(lbl_deaths)
	right.add_child(UI.label("Seed %d" % int(Global.run["seed"]), 18, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_RIGHT))
	lbl_wind = UI.label("", 20, Color(0.8, 0.95, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(lbl_wind)

	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fill)
	lbl_hint = UI.label("WASD / ZQSD / flèches : bouger   •   Espace : sauter (double saut)   •   Souris : caméra   •   Échap : pause   •   R : recommencer l'étape", 18, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(lbl_hint)
	root.add_child(UI.label("Modificateurs : " + Global.mod_summary(), 18, Color(0.7, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER))
	if not Global.options["hint"]:
		lbl_hint.visible = false

	var tw := create_tween()
	tw.tween_interval(10.0)
	tw.tween_property(lbl_hint, "modulate:a", 0.0, 1.5)

	overlay = Overlay.new()
	overlay.pause_toggled.connect(_toggle_pause)
	add_child(overlay)
	_update_hud()


# ---------------------------------------------------------------- boucle

func _process(delta: float) -> void:
	if state != "play":
		return
	time += delta
	if Global.mods["timer"] and time >= par:
		_fail("Temps écoulé !")
		return
	_update_hud()


func _physics_process(delta: float) -> void:
	if state != "play":
		return
	if lava_mesh:
		lava_y += (0.14 + 0.03 * stage) * delta
		lava_mesh.position.y = lava_y
		if player.global_position.y < lava_y:
			_respawn()
			return
	if player.global_position.y < kill_y:
		_respawn()


func _unhandled_input(event: InputEvent) -> void:
	if state == "play" and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _update_hud() -> void:
	if Global.mods["timer"]:
		lbl_time.text = "%s  (reste %s)" % [Global.format_time(time), Global.format_time(maxf(par - time, 0.0))]
	else:
		lbl_time.text = Global.format_time(time)
	lbl_coins.text = "Pièces : %d / %d" % [coins_got, coins_total]
	lbl_deaths.text = "Chutes : %d" % deaths
	if Global.mods["wind"] and player:
		var w: Vector3 = player.wind_vec
		lbl_wind.text = "Vent : %s" % ("fort" if w.length() > 2.2 else ("léger" if w.length() > 0.8 else "calme"))


func set_checkpoint(pos: Vector3) -> void:
	checkpoint = pos


func _respawn() -> void:
	Global.play_sfx("fall")
	if Global.mods["hardcore"]:
		_fail("Tu es tombé ! (mode Hardcore)")
		return
	deaths += 1
	player.teleport(checkpoint)
	if lava_mesh:
		lava_y = minf(lava_y, checkpoint.y - 9.0)


func _on_pickup(kind: String, pk: Node) -> void:
	if state != "play":
		return
	if kind == "coin":
		coins_got += 1
		Global.play_sfx("coin")
		Fx.burst(self, pk.global_position, Color(1.0, 0.85, 0.2), 10, 3.0, false)
		pk.queue_free()
	elif kind == "diamond":
		_win()


# ---------------------------------------------------------------- fin d'étape

func _calc_score() -> int:
	var base: int = 1000 + coins_got * 150 + int(maxf(0.0, par - time) * 10.0)
	return int(base * Global.multiplier())


func _win() -> void:
	state = "won"
	player.controls_enabled = false
	Global.play_sfx("win")
	Fx.burst(self, player.global_position + Vector3(0, 1, 0), Color(0.4, 0.95, 1.0), 40, 6.0, false)
	var score := _calc_score()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var after: String = Global.Story.STAGES[stage]["after"]
	var lines: Array = [
		after,
		"Temps : %s   •   Pièces : %d / %d   •   Chutes : %d" % [Global.format_time(time), coins_got, coins_total, deaths],
		"Score de l'étape : %d (x%.2f)" % [score, Global.multiplier()],
	]
	var last := stage + 1 >= Global.STAGE_COUNT
	var buttons: Array = [
		["Terminer la run" if last else "Étape suivante", _continue_run.bind(score)],
		["Rejouer cette étape", _restart],
		["Abandonner (menu)", _abandon],
	]
	_show_panel("Éclat %d/%d récupéré !" % [stage + 1, Global.STAGE_COUNT], lines, buttons)


func _continue_run(score: int) -> void:
	Global.stage_cleared(time, score, coins_got, deaths)


func _fail(reason: String) -> void:
	state = "failed"
	player.controls_enabled = false
	Global.play_sfx("lose")
	Global.fail_run()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_panel("Run terminée", [
		reason,
		"Tu étais à l'étape %d/%d — score cumulé : %d" % [stage + 1, Global.STAGE_COUNT, int(Global.run["score"])],
		"L'Ombre l'emporte... mais un gardien ne reste pas à terre.",
	], [
		["Nouvelle tentative (même seed)", _retry_run],
		["Nouvelle run", _new_run],
		["Menu principal", _to_menu],
	])


func _retry_run() -> void:
	Global.start_run(int(Global.run["seed"]), true)


func _new_run() -> void:
	Global.start_run(randi() % 900000 + 100000, true)


func _toggle_pause() -> void:
	if state == "play":
		state = "paused"
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_panel("Pause", ["Modificateurs : " + Global.mod_summary()],
			[["Reprendre", _resume], ["Recommencer l'étape", _restart], ["Abandonner la run (menu)", _abandon]])
	elif state == "paused":
		_resume()


func _resume() -> void:
	_clear_panel()
	state = "play"
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _abandon() -> void:
	Global.fail_run()
	_to_menu()


func _to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Global.stop_music()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _clear_panel() -> void:
	for n in panel_nodes:
		n.queue_free()
	panel_nodes.clear()


func _show_panel(title: String, lines: Array, buttons: Array) -> void:
	_clear_panel()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	overlay.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pn := UI.panel()
	center.add_child(pn)
	var vb := UI.vbox(12)
	pn.add_child(vb)
	vb.add_child(UI.label(title, 40, Color.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	for l in lines:
		var lb := UI.label(String(l), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.custom_minimum_size = Vector2(620, 0)
		vb.add_child(lb)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vb.add_child(gap)
	for b in buttons:
		vb.add_child(UI.button(String(b[0]), b[1], Vector2(420, 54)))
	panel_nodes.append(dim)
	panel_nodes.append(center)

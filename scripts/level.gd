extends Node3D
## Construit l'étape courante de la run (parcours généré), gère HUD, pause, boss, fantôme, victoire et défaite.

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
const TouchControls = preload("res://scripts/touch_controls.gd")
const Achievements = preload("res://scripts/achievements.gd")
const Boss = preload("res://scripts/boss.gd")
const Ghost = preload("res://scripts/ghost.gd")

const HEADINGS: Array[Vector3] = [
	Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0),
]
const MAX_HEARTS := 3

var data: Dictionary
var theme: Dictionary
var world := 0      # indice du monde (thème)
var stage := 0      # position dans la run
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
var got_boost := false
var got_wing := false
var platform_tops: Array = []
var platforms: Array = []
var pickups: Array = []
var touch: CanvasLayer = null

# boss
var boss: Node3D = null
var arena_top := Vector3.ZERO
var arena_half := 10.0
var hearts := MAX_HEARTS
var boss_beaten := false

# fantôme
var ghost_key := ""
var ghost_node: Node3D = null
var ghost_prev_time := -1.0
var ghost_samples := PackedFloat32Array()
var _ghost_acc := 0.0

var overlay: CanvasLayer
var panel_nodes: Array[Node] = []
var lbl_time: Label
var lbl_coins: Label
var lbl_deaths: Label
var lbl_hint: Label
var lbl_wind: Label
var lbl_effects: Label
var lbl_toast: Label
var lbl_boss: Label
var lbl_extra: Label
var toast_queue: Array = []
var toast_busy := false


func _ready() -> void:
	get_tree().paused = false
	stage = int(Global.run["stage"])
	world = Global.current_theme()
	data = Generator.generate(int(Global.run["seed"]), world, stage, Global.length_factor(), int(Global.mods["difficulty"]), Global.generation_extra())
	theme = LevelData.get_themes()[world]
	par = float(data["par"])
	mirror = Global.mods["mirror"]
	_setup_viewport()
	_build_environment()
	_build_course()
	_build_scenery()
	_build_ui()
	_setup_ghost()
	if not Global.use_touch_controls():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Global.play_music(world)
	_show_banner()
	for id in Global.toasts:
		_toast(tr("Succès : ") + tr(Achievements.name_of(String(id))))
	Global.toasts.clear()


func _exit_tree() -> void:
	Global.stats["playtime"] = float(Global.stats["playtime"]) + time


func _setup_viewport() -> void:
	var q := Global.quality()
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][q]


# ---------------------------------------------------------------- construction

func _build_environment() -> void:
	var q := Global.quality()
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
	env.glow_enabled = q >= 1
	env.glow_intensity = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.shadow_enabled = bool(Global.options["shadows"]) and q >= 1
	sun.directional_shadow_max_distance = 90.0
	if world == 11 or world == 10:
		sun.light_energy = 0.6
	add_child(sun)


func _half(sz: Vector2, heading: int) -> float:
	return (sz.y if heading % 2 == 0 else sz.x) / 2.0


func _mx(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z) if mirror else v


func _make_platform(top: Vector3, sz: Vector2, kind: String, f: Vector3, idx: int) -> void:
	if kind == "n" and Global.mods["crumble"] and idx > 0:
		kind = "f"
	var r: Vector3 = f.cross(Vector3.UP)
	var p := Platform.new()
	p.kind = kind
	p.size = Vector3(sz.x, 1.0, sz.y)
	p.top_color = theme["top"]
	p.side_color = theme["side"]
	p.theme_idx = world
	p.prop_seed = hash([Global.run["seed"], world, stage, idx])
	p.move_axis = _mx(r)
	p.forward = _mx(f)
	p.level = self
	p.position = _mx(top) - Vector3(0, 0.5, 0)
	add_child(p)
	platforms.append(p)
	platform_tops.append(_mx(top))


func _make_pickup(pos: Vector3, kind: String) -> void:
	var pk := Pickup.new()
	pk.kind = kind
	pk.position = pos
	pk.collected.connect(_on_pickup.bind(pk))
	add_child(pk)
	pickups.append(pk)


func _build_course() -> void:
	var steps: Array = data["steps"]
	var is_boss: bool = bool(data.get("boss", false))
	var pos := Vector3.ZERO # centre du dessus de la plateforme courante
	var heading := 0
	var prev_size := Vector2(8, 8)
	var min_y := 0.0
	_make_platform(pos, prev_size, "n", HEADINGS[0], 0)

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
		min_y = minf(min_y, pos.y - (2.0 if kind == "l" else 0.0))
		_make_platform(pos, sz, kind, f, i + 1)

		var last := i == steps.size() - 1
		if last and is_boss:
			arena_top = _mx(pos)
			arena_half = minf(sz.x, sz.y) * 0.5 - 1.0
		elif last:
			_make_pickup(_mx(pos + Vector3(0, 1.5, 0)), "diamond")
		elif i % 2 == 1 and kind in ["n", "c"]:
			_make_pickup(_mx(pos + Vector3(0, 1.3, 0)), "coin")
			coins_total += 1

	# paires interrupteur -> pont et portail d'entrée -> sortie
	for i in platforms.size() - 1:
		var pl = platforms[i]
		if pl.kind == "y" or pl.kind == "p":
			pl.partner = platforms[i + 1]

	# bonus flottants au-dessus de certains vides
	for pu in data["powerups"]:
		var si: int = int(pu[0])
		if si + 1 < platform_tops.size():
			var a: Vector3 = platform_tops[si]
			var b: Vector3 = platform_tops[si + 1]
			var mid := (a + b) * 0.5
			mid.y = maxf(a.y, b.y) + 2.4
			_make_pickup(mid, String(pu[1]))

	kill_y = min_y - 18.0
	player = PlayerScript.new()
	player.position = Vector3(0, 0.3, 0)
	player.theme_idx = world
	player.world_ice = bool(theme.get("ice", false))
	player.world_wind = bool(theme.get("wind", false))
	add_child(player)
	player.got_hit.connect(_on_player_hit)
	Fx.ambient(player, world, theme["particle"], Global.quality())

	if is_boss:
		boss = Boss.new()
		add_child(boss)
		boss.setup(player, arena_top, arena_half, float(data["difficulty"]))
		boss.defeated.connect(_on_boss_defeated)
		boss.progress.connect(_on_boss_progress)

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
	rng.seed = hash([Global.run["seed"], world, 31337])
	var node := Node3D.new()
	add_child(node)
	Decor.scenery(node, world, (lo + hi) * 0.5, (hi - lo) * 0.5, lo.y, platform_tops, rng, Global.quality())


func _build_ui() -> void:
	var m := Global.safe_margins()
	var hud := CanvasLayer.new()
	add_child(hud)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20 + int(m["left"]))
	margin.add_theme_constant_override("margin_right", 20 + int(m["right"]))
	margin.add_theme_constant_override("margin_top", 20 + int(m["top"]))
	margin.add_theme_constant_override("margin_bottom", 20 + int(m["bottom"]))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(margin)
	var root := VBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var left := UI.vbox(2)
	top.add_child(left)
	var title := tr("Étape %d/%d — %s") % [stage + 1, Global.stage_total(), tr(data["name"])]
	if Global.run["mode"] == "free":
		title = tr(data["name"])
	elif Global.is_endless():
		title = tr("Étape %d — %s") % [stage + 1, tr(data["name"])]
	left.add_child(UI.label(title, 28, Color(1, 0.95, 0.6)))
	lbl_time = UI.label("00:00.0", 26)
	left.add_child(lbl_time)
	lbl_effects = UI.label("", 22, Color(1.0, 0.85, 0.4))
	left.add_child(lbl_effects)
	lbl_extra = UI.label("", 20, Color(0.8, 1.0, 0.8))
	left.add_child(lbl_extra)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var right := UI.vbox(2)
	top.add_child(right)
	lbl_coins = UI.label("", 26, Color(1, 0.85, 0.2), HORIZONTAL_ALIGNMENT_RIGHT)
	lbl_deaths = UI.label("", 22, Color(1, 0.6, 0.6), HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(lbl_coins)
	right.add_child(lbl_deaths)
	right.add_child(UI.label(tr("Seed %d") % int(Global.run["seed"]), 18, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_RIGHT))
	lbl_wind = UI.label("", 20, Color(0.8, 0.95, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	right.add_child(lbl_wind)

	lbl_boss = UI.label("", 26, Color(1.0, 0.5, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	lbl_boss.visible = false
	root.add_child(lbl_boss)

	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fill)
	lbl_toast = UI.label("", 26, Color(1.0, 0.9, 0.4), HORIZONTAL_ALIGNMENT_CENTER)
	lbl_toast.modulate.a = 0.0
	root.add_child(lbl_toast)
	var hint := tr("WASD / ZQSD / flèches : bouger   •   Espace : sauter (double saut)   •   Souris : caméra   •   Échap : pause   •   R : recommencer l'étape")
	if Global.use_touch_controls():
		hint = tr("Joystick à gauche : bouger   •   SAUT à droite (appuie en l'air : double saut)   •   Glisse à droite : caméra")
	lbl_hint = UI.label(hint, 18, Color(1, 1, 1, 0.9), HORIZONTAL_ALIGNMENT_CENTER)
	lbl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(lbl_hint)
	var ml := UI.label(tr("Modificateurs : ") + Global.mod_summary(), 18, Color(0.7, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(ml)
	if not Global.options["hint"]:
		lbl_hint.visible = false

	var tw := create_tween()
	tw.tween_interval(10.0)
	tw.tween_property(lbl_hint, "modulate:a", 0.0, 1.5)

	overlay = Overlay.new()
	overlay.pause_toggled.connect(_toggle_pause)
	add_child(overlay)

	if Global.use_touch_controls():
		touch = TouchControls.new()
		touch.player = player
		touch.pause_pressed.connect(_toggle_pause)
		add_child(touch)
	_update_hud()


func _show_banner() -> void:
	var b := UI.label(tr(data["name"]), 56, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	var sub_text := tr("Difficulté %s") % LevelData.difficulty_stars(float(theme["difficulty"]))
	if boss:
		sub_text += "   •   " + tr("Boss à la fin !")
	var sub := UI.label(sub_text, 26, Color(1.0, 0.9, 0.5), HORIZONTAL_ALIGNMENT_CENTER)
	var box := UI.vbox(4)
	box.add_child(b)
	box.add_child(sub)
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(box)
	box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.5)
	tw.tween_interval(1.6)
	tw.tween_property(box, "modulate:a", 0.0, 0.8)
	tw.tween_callback(layer.queue_free)


func _setup_ghost() -> void:
	ghost_key = Global.ghost_key(int(Global.run["seed"]), world, stage)
	if not Global.options["ghost"]:
		return
	var g := Global.get_ghost(ghost_key)
	if g.is_empty():
		return
	ghost_prev_time = float(g["time"])
	ghost_node = Ghost.new()
	ghost_node.samples = g["data"]
	add_child(ghost_node)


# ---------------------------------------------------------------- boucle

func _process(delta: float) -> void:
	if state != "play":
		return
	time += delta
	if Global.mods["timer"] and time >= par:
		_fail(tr("Temps écoulé !"))
		return
	_update_hud()


func _physics_process(delta: float) -> void:
	if state != "play":
		return
	_ghost_acc += delta
	if _ghost_acc >= 0.1:
		_ghost_acc -= 0.1
		var p := player.global_position
		ghost_samples.append_array(PackedFloat32Array([p.x, p.y, p.z, player.model.rotation.y]))
	if lava_mesh:
		lava_y += (0.14 + 0.012 * float(theme["difficulty"])) * delta
		lava_mesh.position.y = lava_y
		if player.global_position.y < lava_y:
			_respawn()
			return
	if player.global_position.y < kill_y:
		_respawn()
		return
	# le boss se réveille quand Lumi entre dans l'arène
	if boss and not boss.active and not boss.finished and player.is_on_floor():
		var d := player.global_position - arena_top
		if absf(d.x) < arena_half + 0.5 and absf(d.z) < arena_half + 0.5 and absf(d.y) < 1.0:
			boss.start()
			hearts = MAX_HEARTS
			lbl_boss.visible = true
			_toast(tr("L'Ombre se réveille ! Survis à ses attaques."))


func _unhandled_input(event: InputEvent) -> void:
	if state == "play" and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func _notification(what: int) -> void:
	# bouton « retour » d'Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play" and Global.is_touch_device():
		_toggle_pause()


func _update_hud() -> void:
	if Global.mods["timer"]:
		lbl_time.text = "%s  (%s %s)" % [Global.format_time(time), tr("reste"), Global.format_time(maxf(par - time, 0.0))]
	else:
		lbl_time.text = Global.format_time(time)
	lbl_coins.text = tr("Pièces : %d / %d") % [coins_got, coins_total]
	lbl_deaths.text = tr("Chutes : %d") % deaths
	var extra := ""
	if Global.is_endless():
		extra = tr("Vies : %d   •   Score : %d") % [int(Global.run["lives"]), int(Global.run["score"])]
	elif String(Global.run["challenge"]) != "":
		extra = tr("Défi : ") + Global.challenge_objective_text(Global.run["objective"])
	if ghost_node and ghost_node.visible:
		extra += ("   " if extra != "" else "") + tr("Fantôme : %s") % Global.format_time(ghost_prev_time)
	lbl_extra.text = extra
	if player:
		var eff := ""
		if player.boost_t > 0.0:
			eff += tr("Boost %ds") % int(ceil(player.boost_t)) + "  "
		if player.wing_t > 0.0:
			eff += tr("Ailes %ds") % int(ceil(player.wing_t))
		lbl_effects.text = eff
		if Global.mods["wind"] or bool(theme.get("wind", false)):
			var w: Vector3 = player.wind_vec
			lbl_wind.text = tr("Vent : %s") % (tr("fort") if w.length() > 2.2 else (tr("léger") if w.length() > 0.8 else tr("calme")))
	if boss and lbl_boss.visible:
		var ratio := clampf(boss.elapsed / boss.duration, 0.0, 1.0)
		var bar := "#".repeat(int((1.0 - ratio) * 20.0)) + ".".repeat(20 - int((1.0 - ratio) * 20.0))
		lbl_boss.text = tr("Ombre") + " [" + bar + "]   " + tr("Vie : %d/%d") % [hearts, MAX_HEARTS]


func set_checkpoint(pos: Vector3) -> void:
	checkpoint = pos


func _respawn() -> void:
	Global.play_sfx("fall")
	Global.vibrate(80)
	Global.stats["falls"] = int(Global.stats["falls"]) + 1
	if Global.is_endless():
		Global.run["lives"] = int(Global.run["lives"]) - 1
		if int(Global.run["lives"]) <= 0 or Global.mods["hardcore"]:
			_endless_over()
			return
	elif Global.mods["hardcore"]:
		_fail(tr("Tu es tombé ! (mode Hardcore)"))
		return
	deaths += 1
	player.teleport(checkpoint)
	if boss and boss.active:
		boss.reset()
		hearts = MAX_HEARTS
	if lava_mesh:
		lava_y = minf(lava_y, checkpoint.y - 9.0)


func _on_player_hit(_from: Vector3) -> void:
	if state != "play":
		return
	if boss and boss.active:
		hearts -= 1
		if hearts <= 0:
			_boss_wins()


func _boss_wins() -> void:
	if Global.is_endless():
		return
	if Global.mods["hardcore"]:
		_fail(tr("L'Ombre t'a vaincu ! (mode Hardcore)"))
		return
	deaths += 1
	hearts = MAX_HEARTS
	boss.reset()
	lbl_boss.visible = false
	player.teleport(checkpoint)
	_toast(tr("L'Ombre t'a repoussé... reviens au combat !"))


func _on_boss_progress(_ratio: float) -> void:
	pass


func _on_boss_defeated() -> void:
	boss_beaten = true
	Global.stats["bosses"] = int(Global.stats["bosses"]) + 1
	lbl_boss.visible = false
	_toast(tr("L'Ombre est vaincue !"))
	_make_pickup(arena_top + Vector3(0, 1.5, 0), "diamond")


func _on_pickup(kind: String, pk: Node) -> void:
	if state != "play":
		return
	match kind:
		"coin":
			coins_got += 1
			Global.play_sfx("coin")
			Fx.burst(self, pk.global_position, Color(1.0, 0.85, 0.2), 10, 3.0, false)
			pk.queue_free()
		"boost", "wing":
			player.add_effect(kind)
			if kind == "boost":
				got_boost = true
			else:
				got_wing = true
			Global.play_sfx("boost" if kind == "boost" else "wing")
			Global.vibrate(25)
			Fx.burst(self, pk.global_position, Color(1.0, 0.7, 0.3) if kind == "boost" else Color(0.8, 0.95, 1.0), 14, 3.5, false)
			pk.queue_free()
		"diamond":
			_win()


# ---------------------------------------------------------------- succès (annonces)

func _toast(text: String) -> void:
	toast_queue.append(text)
	if not toast_busy:
		_next_toast()


func _next_toast() -> void:
	if toast_queue.is_empty():
		toast_busy = false
		return
	toast_busy = true
	lbl_toast.text = String(toast_queue.pop_front())
	var tw := create_tween()
	tw.tween_property(lbl_toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.4)
	tw.tween_property(lbl_toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_next_toast)


# ---------------------------------------------------------------- fin d'étape

func _calc_score() -> int:
	var base: int = 1000 + coins_got * 150 + int(maxf(0.0, par - time) * 10.0)
	if Global.is_endless():
		base += stage * 100
	return int(base * Global.multiplier())


func _win() -> void:
	state = "won"
	player.controls_enabled = false
	if touch:
		touch.set_active(false)
	Global.play_jingle("win")
	Global.vibrate(120)
	Fx.burst(self, player.global_position + Vector3(0, 1, 0), Color(0.4, 0.95, 1.0), 40, 6.0, false)
	var score := _calc_score()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	Global.stats["coins"] = int(Global.stats["coins"]) + coins_got
	Global.stats["stages"] = int(Global.stats["stages"]) + 1
	if not (Global.stats["worlds"] as Array).has(world):
		(Global.stats["worlds"] as Array).append(world)
	var beat_ghost := ghost_prev_time >= 0.0 and time < ghost_prev_time
	var new_ghost := Global.save_ghost(ghost_key, time, ghost_samples)
	var got := Achievements.evaluate_stage(Global, {
		"time": time, "par": par, "deaths": deaths, "coins": coins_got, "coins_total": coins_total,
		"length": int(Global.mods["length"]), "mods": Global.active_mod_count(),
		"hardcore": Global.mods["hardcore"], "expert": int(Global.mods["difficulty"]) == 2,
		"boost": got_boost, "wing": got_wing, "boss": boss_beaten, "beat_ghost": beat_ghost,
	})
	if got.size() > 0:
		Global.play_sfx("achievement")
	Global.save_game()

	var after: String = tr(Global.Story.STAGES[world]["after"])
	var lines: Array = [
		after,
		tr("Temps : %s   •   Pièces : %d / %d   •   Chutes : %d") % [Global.format_time(time), coins_got, coins_total, deaths],
		tr("Score de l'étape : %d (x%.2f)") % [score, Global.multiplier()],
	]
	if beat_ghost:
		lines.append(tr("Tu as battu ton fantôme de %s !") % Global.format_time(ghost_prev_time))
	elif new_ghost:
		lines.append(tr("Nouveau meilleur temps enregistré pour le fantôme."))
	if boss_beaten:
		lines.append(tr("Boss vaincu !"))
	if not got.is_empty():
		var names: Array[String] = []
		for id in got:
			names.append(tr(Achievements.name_of(String(id))))
		lines.append(tr("Succès : ") + ", ".join(names))
	var last := stage + 1 >= Global.stage_total()
	var info := {"time": time, "score": score, "coins": coins_got, "deaths": deaths}
	var buttons: Array = [
		[tr("Terminer") if last else tr("Étape suivante"), _continue_run.bind(info)],
		[tr("Rejouer cette étape"), _restart],
		[tr("Abandonner (menu)"), _abandon],
	]
	_show_panel(tr("Éclat récupéré !") if Global.run["mode"] != "free" else tr("Monde terminé !"), lines, buttons)


func _continue_run(info: Dictionary) -> void:
	Global.stage_cleared(info)


func _endless_over() -> void:
	state = "failed"
	player.controls_enabled = false
	if touch:
		touch.set_active(false)
	Global.play_jingle("lose")
	var rank := Global.fail_run()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var lines: Array = [
		tr("Étapes terminées : %d") % int(Global.run["stage"]),
		tr("Score : %d") % int(Global.run["score"]),
		tr("Meilleure série : %d étapes") % int(Global.stats["endless_best"]),
	]
	if rank > 0:
		lines.append(tr("Classement local : n°%d") % rank)
	_show_panel(tr("Fin de la partie infinie"), lines, [
		[tr("Rejouer"), _new_run],
		[tr("Menu principal"), _to_menu],
	])


func _fail(reason: String) -> void:
	state = "failed"
	player.controls_enabled = false
	if touch:
		touch.set_active(false)
	Global.play_jingle("lose")
	Global.fail_run()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_panel(tr("Run terminée"), [
		reason,
		tr("Tu étais à l'étape %d/%d — score cumulé : %d") % [stage + 1, Global.stage_total(), int(Global.run["score"])],
		tr("L'Ombre l'emporte... mais un gardien ne reste pas à terre."),
	], [
		[tr("Nouvelle tentative (même seed)"), _retry_run],
		[tr("Nouvelle run"), _new_run],
		[tr("Menu principal"), _to_menu],
	])


func _retry_run() -> void:
	Global.restart_run()


func _new_run() -> void:
	Global.start_run(randi() % 900000 + 100000, String(Global.run["mode"]), Global.run["stages"], true)


func _toggle_pause() -> void:
	if state == "play":
		state = "paused"
		get_tree().paused = true
		if touch:
			touch.set_active(false)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_panel(tr("Pause"), [tr("Modificateurs : ") + Global.mod_summary()],
			[[tr("Reprendre"), _resume], [tr("Recommencer l'étape"), _restart], [tr("Abandonner la run (menu)"), _abandon]])
	elif state == "paused":
		_resume()


func _resume() -> void:
	_clear_panel()
	state = "play"
	get_tree().paused = false
	if touch:
		touch.set_active(true)
	if not Global.use_touch_controls():
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
	Global.save_game()
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
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
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
		vb.add_child(UI.button(String(b[0]), b[1], Vector2(420, 58)))
	panel_nodes.append(dim)
	panel_nodes.append(scroll)

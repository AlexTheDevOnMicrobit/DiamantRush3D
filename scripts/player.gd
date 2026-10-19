extends CharacterBody3D
## Lumi, le petit robot : course, saut, double saut, caméra souris, animations.

const Models = preload("res://scripts/models.gd")
const Fx = preload("res://scripts/fx.gd")
const JUMP_VEL := 9.5
const BASE_GRAVITY := 24.0

var controls_enabled := true
var yaw := 0.0
var pitch := 0.35
var cam_dist := 7.0
var mouse_sens := 0.004
var theme_idx := 0

var speed := 7.0
var gravity := BASE_GRAVITY
var air_jumps_max := 1
var air_jumps := 0
var coyote := 0.0
var buffer := 0.0
var was_on_floor := true
var last_vy := 0.0
var wind_t := 0.0
var walk_phase := 0.0
var invert_y := 1.0
var wind_vec := Vector3.ZERO
var world_ice := false
var world_wind := false
var boost_t := 0.0
var wing_t := 0.0
var rainbow := false
var body_mat: StandardMaterial3D
var look_speed := 2.6
var jump_vel := JUMP_VEL
var jumping := false # vrai tant que la montée vient d'un saut (coupable en relâchant Espace)

var pivot: Node3D
var cam: Camera3D
var model: Node3D
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var arm_r: Node3D
var body_root: Node3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.3
	speed = 7.0 * Global.speed_scale()
	gravity = BASE_GRAVITY * Global.gravity_scale()
	# même hauteur de saut quelle que soit la gravité : seule la durée en l'air change
	jump_vel = JUMP_VEL * sqrt(Global.gravity_scale())
	air_jumps_max = 0 if Global.mods["no_double"] else 1
	mouse_sens = 0.004 * float(Global.options["sens"])
	invert_y = -1.0 if Global.options["invert_y"] else 1.0

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)

	var skin := Global.current_skin()
	rainbow = skin["id"] == "rainbow"
	_build_robot(skin["color"])

	pivot = Node3D.new()
	pivot.top_level = true
	add_child(pivot)
	pivot.global_position = global_position + Vector3(0, 1.3, 0)
	cam = Camera3D.new()
	cam.fov = float(Global.options["fov"])
	cam.position = Vector3(0, 0, cam_dist)
	pivot.add_child(cam)
	cam.current = true


func _part(mesh: Mesh, color: Color, parent: Node3D, pos: Vector3, emission: float = 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = Models.material(color, emission, 0.3, 0.45)
	m.position = pos
	parent.add_child(m)
	return m


func _limb(parent: Node3D, pos: Vector3, radius: float, length: float, color: Color) -> Node3D:
	var pv := Node3D.new()
	pv.position = pos
	parent.add_child(pv)
	var cm := CapsuleMesh.new()
	cm.radius = radius
	cm.height = length
	_part(cm, color, pv, Vector3(0, -length * 0.5 + radius, 0))
	return pv


func _build_robot(body_color: Color = Color(1.0, 0.55, 0.15)) -> void:
	model = Node3D.new()
	add_child(model)
	body_root = Node3D.new()
	model.add_child(body_root)
	var orange := body_color
	var steel := Color(0.8, 0.84, 0.9)

	var torso := CapsuleMesh.new()
	torso.radius = 0.3
	torso.height = 0.8
	var tm := _part(torso, orange, body_root, Vector3(0, 0.95, 0))
	body_mat = tm.material_override
	var belt := CylinderMesh.new()
	belt.top_radius = 0.31
	belt.bottom_radius = 0.31
	belt.height = 0.08
	_part(belt, Color(0.2, 0.2, 0.25), body_root, Vector3(0, 0.78, 0))
	var core := SphereMesh.new()
	core.radius = 0.09
	core.height = 0.18
	_part(core, Color(0.4, 0.95, 1.0), body_root, Vector3(0, 1.05, -0.27), 3.0)

	var head := SphereMesh.new()
	head.radius = 0.3
	head.height = 0.6
	_part(head, steel, body_root, Vector3(0, 1.5, 0))
	var visor := BoxMesh.new()
	visor.size = Vector3(0.42, 0.14, 0.12)
	_part(visor, Color(0.3, 0.9, 1.0), body_root, Vector3(0, 1.52, -0.24), 2.5)
	var ant := CylinderMesh.new()
	ant.top_radius = 0.02
	ant.bottom_radius = 0.02
	ant.height = 0.22
	_part(ant, steel, body_root, Vector3(0, 1.9, 0))
	var orb := SphereMesh.new()
	orb.radius = 0.06
	orb.height = 0.12
	_part(orb, Color(1.0, 0.9, 0.2), body_root, Vector3(0, 2.03, 0), 3.0)

	leg_l = _limb(body_root, Vector3(-0.14, 0.62, 0), 0.1, 0.62, steel)
	leg_r = _limb(body_root, Vector3(0.14, 0.62, 0), 0.1, 0.62, steel)
	arm_l = _limb(body_root, Vector3(-0.38, 1.2, 0), 0.075, 0.55, orange.darkened(0.2))
	arm_r = _limb(body_root, Vector3(0.38, 1.2, 0), 0.075, 0.55, orange.darkened(0.2))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative)


## Tourne la caméra (souris, doigt ou manette) ; rel en « pixels souris ».
func look(rel: Vector2) -> void:
	yaw -= rel.x * mouse_sens
	pitch = clampf(pitch + rel.y * mouse_sens * invert_y, -0.2, 1.3)


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if controls_enabled:
		var iv := Input.get_vector("left", "right", "forward", "back")
		if Global.mods["invert"]:
			iv = -iv
		dir = Basis(Vector3.UP, yaw) * Vector3(iv.x, 0, iv.y)

	boost_t = maxf(boost_t - delta, 0.0)
	wing_t = maxf(wing_t - delta, 0.0)
	var look_v := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look_v.length() > 0.0 and controls_enabled:
		var s := float(Global.options["sens"]) * look_speed * delta
		yaw -= look_v.x * s
		pitch = clampf(pitch + look_v.y * s * invert_y, -0.2, 1.3)

	wind_vec = Vector3.ZERO
	if Global.mods["wind"] or world_wind:
		wind_t += delta
		var ang := wind_t * 0.23
		var power := 0.5 * (1.0 + sin(wind_t * 0.6)) * (3.2 if Global.mods["wind"] else 2.0)
		wind_vec = Vector3(cos(ang), 0, sin(ang)) * power

	var on_floor := is_on_floor()
	var accel := 60.0 if on_floor else 32.0
	if Global.mods["ice"] or world_ice:
		accel = 5.0 if on_floor else 20.0
	var cur_speed := speed * (1.4 if boost_t > 0.0 else 1.0)
	var target := dir * cur_speed + wind_vec * (0.3 if on_floor else 1.0)
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)

	if on_floor:
		coyote = 0.12
		air_jumps = air_jumps_max + (1 if wing_t > 0.0 else 0)
	else:
		coyote -= delta
		velocity.y = maxf(velocity.y - gravity * delta, -45.0)

	buffer -= delta
	if controls_enabled and Input.is_action_just_pressed("jump"):
		buffer = 0.12
	if buffer > 0.0:
		if coyote > 0.0:
			_jump(false)
		elif air_jumps > 0:
			air_jumps -= 1
			_jump(true)
	if jumping and Input.is_action_just_released("jump") and velocity.y > 3.0:
		velocity.y *= 0.6
		jumping = false
	if on_floor or velocity.y <= 0.0:
		jumping = false

	last_vy = velocity.y
	move_and_slide()

	if is_on_floor() and not was_on_floor and last_vy < -5.0:
		Global.play_sfx("land", 1.0, -6.0)
		Fx.burst(get_parent(), global_position, Color(1, 1, 1, 0.8), 8, 2.5)
		model.scale = Vector3(1.2, 0.8, 1.2)
	was_on_floor = is_on_floor()

	if dir.length() > 0.1:
		var tgt := atan2(-dir.x, -dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, tgt, 1.0 - exp(-15.0 * delta))


func _jump(double: bool) -> void:
	velocity.y = jump_vel
	jumping = true
	coyote = 0.0
	buffer = 0.0
	model.scale = Vector3(0.8, 1.25, 0.8)
	Global.stats["jumps"] = int(Global.stats["jumps"]) + 1
	Global.play_sfx("jump2" if double else "jump", 1.0, -3.0)
	Fx.burst(get_parent(), global_position, Color(1, 1, 1, 0.8), 6 if not double else 10, 2.0, not double)


func _process(delta: float) -> void:
	var tgt := global_position + Vector3(0, 1.3, 0)
	pivot.global_position = pivot.global_position.lerp(tgt, 1.0 - exp(-14.0 * delta))
	pivot.rotation = Vector3(-pitch, yaw, 0)

	if rainbow and body_mat:
		body_mat.albedo_color = Color.from_hsv(fposmod(Time.get_ticks_msec() / 2500.0, 1.0), 0.7, 1.0)
	# animation
	model.scale = model.scale.lerp(Vector3.ONE, 1.0 - exp(-12.0 * delta))
	var hspeed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor():
		walk_phase += delta * hspeed * 1.5
		var k := clampf(hspeed / 7.0, 0.0, 1.0)
		var sw := sin(walk_phase) * 0.9 * k
		leg_l.rotation.x = sw
		leg_r.rotation.x = -sw
		arm_l.rotation.x = -sw * 0.8
		arm_r.rotation.x = sw * 0.8
		body_root.position.y = absf(sin(walk_phase)) * 0.06 * k
	else:
		var up := velocity.y > 0.0
		var a := -2.6 if up else -1.6
		arm_l.rotation.x = lerpf(arm_l.rotation.x, a, 1.0 - exp(-14.0 * delta))
		arm_r.rotation.x = lerpf(arm_r.rotation.x, a, 1.0 - exp(-14.0 * delta))
		leg_l.rotation.x = lerpf(leg_l.rotation.x, 0.5, 1.0 - exp(-14.0 * delta))
		leg_r.rotation.x = lerpf(leg_r.rotation.x, -0.3, 1.0 - exp(-14.0 * delta))
		body_root.position.y = 0.0


func bounce(power: float) -> void:
	velocity.y = power * sqrt(Global.gravity_scale())
	jumping = false
	air_jumps = air_jumps_max
	coyote = 0.0
	model.scale = Vector3(0.75, 1.35, 0.75)
	Global.play_sfx("bounce")
	Global.vibrate(30)
	Fx.burst(get_parent(), global_position, Color(1.0, 0.5, 0.8), 14, 4.0)


func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	pivot.global_position = pos + Vector3(0, 1.3, 0)


func add_effect(kind: String) -> void:
	match kind:
		"boost":
			boost_t = 6.0
		"wing":
			wing_t = 12.0
			air_jumps = air_jumps_max + 1

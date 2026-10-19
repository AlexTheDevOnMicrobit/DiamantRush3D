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
var coyote_time := 0.12
var buffer_time := 0.12
var hit_cd := 0.0     # invulnérabilité après un coup
var launch_t := 0.0   # après un lanceur : le contrôle aérien est réduit
var ice_count := 0    # nombre de plaques de glace sous Lumi
var model_base := 1.0 # 0.6 avec « Lumi miniature »
var trail: CPUParticles3D
var flash_t := 0.0
var shadow: MeshInstance3D
var shadow_mat: StandardMaterial3D
var want_cam_dist := 7.0

signal got_hit(from_dir: Vector3)

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
	if Global.options["assist"]:
		coyote_time = 0.25
		buffer_time = 0.25

	var tiny: bool = Global.mods["tiny"]
	model_base = 0.6 if tiny else 1.0
	if tiny:
		cam_dist = 5.0
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4 * model_base
	cap.height = 1.8 * model_base
	cs.shape = cap
	cs.position.y = 0.9 * model_base
	add_child(cs)

	var skin := Global.current_skin()
	rainbow = skin["id"] == "rainbow"
	_build_robot(skin["color"])
	model.scale = Vector3.ONE * model_base
	_build_hat(Global.current_hat())
	_build_trail(Global.current_trail())
	if Global.mods["night"]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.92, 0.7)
		lamp.omni_range = 11.0
		lamp.light_energy = 3.0
		lamp.position = Vector3(0, 1.6 * model_base, 0)
		add_child(lamp)

	pivot = Node3D.new()
	pivot.top_level = true
	add_child(pivot)
	pivot.global_position = global_position + Vector3(0, 1.3, 0)
	cam = Camera3D.new()
	cam.fov = float(Global.options["fov"])
	cam.position = Vector3(0, 0, cam_dist)
	pivot.add_child(cam)
	cam.current = true

	# disque d'ombre sous Lumi : montre où il va atterrir
	shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.02
	disc.radial_segments = 16
	shadow.mesh = disc
	shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0, 0, 0, 0.45)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = shadow_mat
	shadow.top_level = true
	shadow.visible = false
	add_child(shadow)


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
	hit_cd = maxf(hit_cd - delta, 0.0)
	launch_t = maxf(launch_t - delta, 0.0)
	flash_t = maxf(flash_t - delta, 0.0)
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
	if Global.mods["ice"] or world_ice or ice_count > 0:
		accel = 5.0 if on_floor else 20.0
	if launch_t > 0.0 and not on_floor:
		accel = 2.0
	var cur_speed := speed * (1.4 if boost_t > 0.0 else 1.0)
	var target := dir * cur_speed + wind_vec * (0.3 if on_floor else 1.0)
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)

	if on_floor:
		coyote = coyote_time
		air_jumps = air_jumps_max + (1 if wing_t > 0.0 else 0)
	else:
		coyote -= delta
		velocity.y = maxf(velocity.y - gravity * delta, -45.0)

	buffer -= delta
	if controls_enabled and Input.is_action_just_pressed("jump"):
		buffer = buffer_time
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

	_update_shadow_and_camera()


## Ombre au sol et caméra qui ne traverse pas les dalles.
func _update_shadow_and_camera() -> void:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 0.5, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -40, 0), 1)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		shadow.visible = false
	else:
		var h: float = from.y - float(hit["position"].y)
		shadow.visible = true
		shadow.global_position = hit["position"] + Vector3(0, 0.03, 0)
		var s := clampf(1.0 - h * 0.04, 0.35, 1.0)
		shadow.scale = Vector3(s, 1.0, s)
		shadow_mat.albedo_color.a = clampf(0.5 - h * 0.012, 0.12, 0.5)
	# caméra : raccourcit la distance si une dalle est entre Lumi et la caméra
	var origin := pivot.global_position
	var desired := pivot.global_transform.basis * Vector3(0, 0, cam_dist)
	var cq := PhysicsRayQueryParameters3D.create(origin, origin + desired, 1)
	var ch := space.intersect_ray(cq)
	want_cam_dist = cam_dist
	if not ch.is_empty():
		want_cam_dist = maxf(1.2, origin.distance_to(ch["position"]) - 0.4)


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
	cam.position.z = lerpf(cam.position.z, want_cam_dist, 1.0 - exp(-(18.0 if want_cam_dist < cam.position.z else 4.0) * delta))

	if flash_t > 0.0:
		model.visible = int(flash_t * 16.0) % 2 == 0
	else:
		model.visible = true

	if rainbow and body_mat:
		body_mat.albedo_color = Color.from_hsv(fposmod(Time.get_ticks_msec() / 2500.0, 1.0), 0.7, 1.0)
	if trail:
		trail.emitting = Vector2(velocity.x, velocity.z).length() > 1.5 or not is_on_floor()
		trail.global_position = global_position + Vector3(0, 0.3, 0)
	# animation
	model.scale = model.scale.lerp(Vector3.ONE * model_base, 1.0 - exp(-12.0 * delta))
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


## Coup reçu (projectile, boss) : projette Lumi à l'opposé de la source. Retourne faux si invulnérable.
func get_hit(from_pos: Vector3, power: float = 9.0) -> bool:
	if hit_cd > 0.0:
		return false
	hit_cd = 1.2
	flash_t = 1.2
	var away := global_position - from_pos
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	velocity = away * power + Vector3(0, 6.0, 0)
	coyote = 0.0
	Global.play_sfx("hit")
	Global.vibrate(60)
	Fx.burst(get_parent(), global_position + Vector3(0, 1, 0), Color(1.0, 0.3, 0.2), 14, 4.0, false)
	got_hit.emit(from_pos)
	return true


## Lance Lumi (tremplin directionnel).
func launch(vel: Vector3) -> void:
	velocity = vel
	launch_t = 0.8 / sqrt(Global.gravity_scale())
	jumping = false
	air_jumps = air_jumps_max
	coyote = 0.0
	model.scale = Vector3(0.8, 1.3, 0.8)
	Global.play_sfx("launch")
	Global.vibrate(30)
	Fx.burst(get_parent(), global_position, Color(1.0, 0.9, 0.3), 14, 4.0)


## Chapeau (débloqué avec les étoiles) posé sur la tête de Lumi.
func _build_hat(id: String) -> void:
	if id == "none":
		return
	var hat := Node3D.new()
	hat.position = Vector3(0, 1.78, 0)
	body_root.add_child(hat)
	match id:
		"beanie":
			_part(_cone(0.34, 0.45), Color(0.9, 0.15, 0.2), hat, Vector3(0, 0.12, 0))
			_part(_ball(0.1), Color(1, 1, 1), hat, Vector3(0, 0.4, 0))
		"crown":
			var ring := CylinderMesh.new()
			ring.top_radius = 0.26
			ring.bottom_radius = 0.28
			ring.height = 0.16
			_part(ring, Color(1.0, 0.82, 0.2), hat, Vector3(0, 0.05, 0), 0.8)
			for i in 5:
				var a := TAU * float(i) / 5.0
				_part(_cone(0.07, 0.2), Color(1.0, 0.82, 0.2), hat, Vector3(cos(a) * 0.24, 0.22, sin(a) * 0.24), 0.8)
		"tophat":
			var tube := CylinderMesh.new()
			tube.top_radius = 0.2
			tube.bottom_radius = 0.2
			tube.height = 0.42
			_part(tube, Color(0.08, 0.08, 0.1), hat, Vector3(0, 0.2, 0))
			var brim := CylinderMesh.new()
			brim.top_radius = 0.36
			brim.bottom_radius = 0.36
			brim.height = 0.04
			_part(brim, Color(0.08, 0.08, 0.1), hat, Vector3(0, 0.0, 0))
			var band := CylinderMesh.new()
			band.top_radius = 0.205
			band.bottom_radius = 0.205
			band.height = 0.08
			_part(band, Color(0.8, 0.1, 0.15), hat, Vector3(0, 0.08, 0))
		"viking":
			var dome := SphereMesh.new()
			dome.radius = 0.33
			dome.height = 0.5
			_part(dome, Color(0.6, 0.62, 0.68), hat, Vector3(0, 0.0, 0), 0.0)
			for sx in [-1.0, 1.0]:
				var horn := _part(_cone(0.07, 0.4), Color(0.95, 0.92, 0.8), hat, Vector3(0.34 * sx, 0.12, 0))
				horn.rotation_degrees.z = -35.0 * sx
		"halo":
			var tm := TorusMesh.new()
			tm.inner_radius = 0.22
			tm.outer_radius = 0.3
			tm.rings = 18
			tm.ring_segments = 6
			_part(tm, Color(1.0, 0.9, 0.3), hat, Vector3(0, 0.45, 0), 3.0)
		"devil":
			for sx2 in [-1.0, 1.0]:
				var horn2 := _part(_cone(0.07, 0.3), Color(0.85, 0.05, 0.1), hat, Vector3(0.18 * sx2, 0.1, 0), 0.8)
				horn2.rotation_degrees.z = -20.0 * sx2


func _cone(radius: float, height: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 8
	return c


func _ball(radius: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	return sm


## Traînée de particules (débloquée avec les étoiles).
func _build_trail(id: String) -> void:
	if id == "none":
		return
	trail = CPUParticles3D.new()
	trail.local_coords = false
	trail.lifetime = 0.8
	trail.amount = 28
	trail.direction = Vector3.UP
	trail.spread = 25.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.gravity = Vector3.ZERO
	trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 0.2
	var color := Color(1, 1, 1)
	var radius := 0.08
	match id:
		"sparks":
			color = Color(1.0, 0.9, 0.3)
			trail.gravity = Vector3(0, -4.0, 0)
			trail.lifetime = 0.5
			trail.initial_velocity_max = 2.0
		"flames":
			color = Color(1.0, 0.45, 0.1)
			trail.gravity = Vector3(0, 2.5, 0)
			radius = 0.13
		"rainbow":
			radius = 0.1
			var gr := Gradient.new()
			gr.colors = PackedColorArray([Color(1, 0.2, 0.2), Color(1, 0.8, 0.2), Color(0.3, 1, 0.3), Color(0.2, 0.6, 1), Color(0.7, 0.3, 1)])
			gr.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
			trail.color_ramp = gr
		"stars":
			color = Color(1.0, 0.95, 0.4)
			radius = 0.1
			trail.initial_velocity_max = 1.5
		"smoke":
			color = Color(0.7, 0.7, 0.75)
			trail.gravity = Vector3(0, 1.0, 0)
			radius = 0.16
			trail.scale_amount_max = 2.0
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = m
	trail.mesh = sm
	if id != "rainbow":
		trail.color = color
	trail.emitting = false
	add_child(trail)

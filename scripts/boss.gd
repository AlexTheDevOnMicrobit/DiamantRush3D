extends Node3D
## L'Ombre : boss de fin des mondes 3, 6, 9 et 12. Il faut survivre à ses attaques jusqu'à ce qu'il s'effondre.
##   - Balayage : une rangée de boules traverse l'arène (à sauter)
##   - Météores : un cercle rouge au sol, puis l'impact
##   - Tir ciblé : une boule qui vise Lumi

signal defeated
signal progress(ratio: float)

const Models = preload("res://scripts/models.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Fx = preload("res://scripts/fx.gd")

var player: Node3D
var center := Vector3.ZERO     # centre du dessus de l'arène
var half := 11.0               # demi-côté de l'arène
var difficulty := 5.0
var active := false
var finished := false
var duration := 40.0
var elapsed := 0.0

var _cd := 2.0
var _eye_mat: StandardMaterial3D
var _body: Node3D
var _bob := 0.0


func setup(p: Node3D, arena_center: Vector3, arena_half: float, diff: float) -> void:
	player = p
	center = arena_center
	half = arena_half
	difficulty = diff
	duration = 26.0 + diff * 2.2
	position = center + Vector3(0, 9.5, 0)
	_build()


func _build() -> void:
	_body = Node3D.new()
	add_child(_body)
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 2.2
	sm.height = 4.4
	sm.radial_segments = 14
	sm.rings = 7
	core.mesh = sm
	core.material_override = Models.material(Color(0.12, 0.05, 0.2), 0.3, 0.4, 0.4)
	_body.add_child(core)
	for i in 8:
		var spike := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.45
		cm.height = 1.6
		cm.radial_segments = 5
		spike.mesh = cm
		spike.material_override = Models.material(Color(0.2, 0.08, 0.3), 0.5)
		var a := TAU * float(i) / 8.0
		spike.position = Vector3(cos(a) * 2.3, 0.0, sin(a) * 2.3)
		spike.rotation = Vector3(0, -a, -PI * 0.5)
		_body.add_child(spike)
	var eye := MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = 0.8
	em.height = 1.6
	eye.mesh = em
	_eye_mat = Models.material(Color(1.0, 0.1, 0.1), 2.0)
	eye.material_override = _eye_mat
	eye.position = Vector3(0, 0.2, 1.9)
	_body.add_child(eye)
	var light := OmniLight3D.new()
	light.light_color = Color(0.8, 0.2, 1.0)
	light.omni_range = 18.0
	light.light_energy = 1.5
	_body.add_child(light)


func start() -> void:
	if active or finished:
		return
	active = true
	elapsed = 0.0
	_cd = 2.0
	Global.play_sfx("lose", 0.6, -4.0)


## Appelé quand Lumi est battu ou tombe : l'Ombre repart de zéro.
func reset() -> void:
	active = false
	elapsed = 0.0
	progress.emit(0.0)
	for n in get_parent().get_children():
		if n is Projectile or n.is_in_group("boss_fx"):
			n.queue_free()


func _physics_process(delta: float) -> void:
	_bob += delta
	_body.position.y = sin(_bob * 1.4) * 0.4
	_body.rotation.y += delta * 0.3
	if player:
		var to := (player.global_position - global_position)
		var tgt := atan2(to.x, to.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, tgt, 1.0 - exp(-2.0 * delta))
	if not active or finished:
		return
	elapsed += delta
	var ratio := clampf(elapsed / duration, 0.0, 1.0)
	progress.emit(ratio)
	if ratio >= 1.0:
		_defeat()
		return
	_cd -= delta
	if _cd <= 0.0:
		var pace := lerpf(2.3, 1.1, ratio) - difficulty * 0.04
		_cd = maxf(pace, 0.7)
		_attack(ratio)


func _attack(ratio: float) -> void:
	_eye_mat.emission_energy_multiplier = 6.0
	get_tree().create_timer(0.25).timeout.connect(func(): _eye_mat.emission_energy_multiplier = 2.0)
	var roll := randi() % 3
	if ratio < 0.2:
		roll = randi() % 2 + 1 # début : pas de balayage trop dur
	match roll:
		0: _sweep(ratio)
		1: _meteors(ratio)
		_: _aimed()


func _shot_height() -> float:
	return center.y + 0.9


func _sweep(ratio: float) -> void:
	# rangée de boules le long d'un côté, avec un trou à sauter ou à traverser
	var axis := randi() % 2
	var sgn := 1.0 if randf() < 0.5 else -1.0
	var speed := 6.5 + ratio * 2.5
	var count := int(half * 2.0 / 2.6)
	var gap_i := randi() % count
	for i in count:
		if i == gap_i or i == gap_i + 1:
			continue
		var lateral := -half + (float(i) + 0.5) * (half * 2.0 / float(count))
		var shot := Projectile.new()
		shot.radius = 0.45
		shot.power = 8.0
		shot.color = Color(0.8, 0.2, 1.0)
		var start := Vector3.ZERO
		var v := Vector3.ZERO
		if axis == 0:
			start = Vector3(center.x - sgn * (half + 0.5), _shot_height(), center.z + lateral)
			v = Vector3(sgn * speed, 0, 0)
		else:
			start = Vector3(center.x + lateral, _shot_height(), center.z - sgn * (half + 0.5))
			v = Vector3(0, 0, sgn * speed)
		shot.position = start
		shot.velocity = v
		shot.life = (half * 2.0 + 1.5) / speed
		get_parent().add_child(shot)
	Global.play_sfx("crumble", 0.8, -4.0)


func _meteors(ratio: float) -> void:
	var n := 2 + int(ratio * 3.0 + difficulty * 0.15)
	for i in n:
		var target := center
		if i == 0 and player:
			target = Vector3(player.global_position.x, center.y, player.global_position.z)
		else:
			target = center + Vector3(randf_range(-half + 1.5, half - 1.5), 0, randf_range(-half + 1.5, half - 1.5))
		_meteor_at(target, 1.0 - ratio * 0.25)


func _meteor_at(target: Vector3, warn: float) -> void:
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 1.8
	dm.bottom_radius = 1.8
	dm.height = 0.03
	disc.mesh = dm
	var mat := Models.material(Color(1.0, 0.15, 0.1, 0.45), 1.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material_override = mat
	disc.add_to_group("boss_fx")
	disc.position = target + Vector3(0, 0.06, 0)
	get_parent().add_child(disc)
	var tw := create_tween()
	tw.tween_interval(warn)
	tw.tween_callback(_impact.bind(disc, target))


func _impact(disc: MeshInstance3D, target: Vector3) -> void:
	if not is_instance_valid(disc):
		return
	Fx.burst(get_parent(), target + Vector3(0, 0.5, 0), Color(1.0, 0.4, 0.1), 24, 6.0)
	Global.play_sfx("land", 0.7)
	if player and active and not finished:
		var d := Vector2(player.global_position.x - target.x, player.global_position.z - target.z).length()
		if d < 1.9 and player.global_position.y < target.y + 1.6:
			player.get_hit(target, 10.0)
	disc.queue_free()


func _aimed() -> void:
	if not player:
		return
	var shot := Projectile.new()
	shot.radius = 0.6
	shot.power = 9.0
	shot.color = Color(1.0, 0.2, 0.5)
	shot.position = global_position + Vector3(0, -1.5, 0)
	var target := player.global_position + Vector3(0, 1.0, 0)
	shot.velocity = (target - shot.position).normalized() * (7.5 + difficulty * 0.2)
	shot.life = 4.0
	get_parent().add_child(shot)
	Global.play_sfx("crumble", 1.3, -4.0)


func _defeat() -> void:
	finished = true
	active = false
	for n in get_parent().get_children():
		if n is Projectile or n.is_in_group("boss_fx"):
			n.queue_free()
	Fx.burst(get_parent(), global_position, Color(0.8, 0.3, 1.0), 60, 10.0, false)
	Global.play_sfx("win", 0.8)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 1.2)
	tw.tween_callback(func(): visible = false)
	defeated.emit()

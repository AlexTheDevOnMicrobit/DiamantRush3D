extends RefCounted
## Effets de particules (CPUParticles3D, aucun asset).


static func make_mesh(color: Color, radius: float) -> SphereMesh:
	return _mesh(color, radius)


static func _mesh(color: Color, radius: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = m
	return sm


## Éclat ponctuel (poussière, étincelles).
static func burst(parent: Node, pos: Vector3, color: Color, amount: int = 12, speed: float = 3.0, up: bool = true) -> void:
	var p := CPUParticles3D.new()
	p.mesh = _mesh(color, 0.07)
	p.amount = amount
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP if up else Vector3.ZERO
	p.spread = 70.0 if up else 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -6, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	parent.get_tree().create_timer(1.0).timeout.connect(p.queue_free)


## Particules d'ambiance qui restent autour du joueur.
static func ambient(parent: Node3D, theme_idx: int, color: Color, quality: int = 2) -> void:
	var p := CPUParticles3D.new()
	p.mesh = _mesh(color, 0.06)
	p.amount = [20, 40, 70][clampi(quality, 0, 2)]
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(22, 10, 22)
	p.direction = Vector3.ZERO
	p.spread = 180.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.8
	var grav := [
		Vector3(0.6, -0.5, 0.2),    # 0 pétales
		Vector3(0.2, 0.15, 0.1),    # 1 lucioles
		Vector3(1.8, -0.2, 0.4),    # 2 sable
		Vector3(0.0, 0.9, 0.0),     # 3 bulles
		Vector3(0.8, -1.4, 0.3),    # 4 neige
		Vector3(0.0, 0.25, 0.0),    # 5 lucioles de cristal
		Vector3(0.0, 1.2, 0.0),     # 6 étincelles
		Vector3(0.3, -0.3, 0.2),    # 7 poussière dorée
		Vector3(0.0, 0.3, 0.0),     # 8 feux follets
		Vector3(0.0, 1.4, 0.0),     # 9 braises
		Vector3(0.0, -0.6, 0.0),    # 10 pluie néon
		Vector3.ZERO,               # 11 poussière d'étoiles
	]
	p.gravity = grav[clampi(theme_idx, 0, grav.size() - 1)]
	parent.add_child(p)
	p.emitting = true

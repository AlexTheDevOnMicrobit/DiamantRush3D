extends Area3D
## Objet à ramasser : "coin" (pièce) ou "diamond" (objectif du niveau).

signal collected(kind: String)

const Models = preload("res://scripts/models.gd")
const Fx = preload("res://scripts/fx.gd")

var kind := "coin"

var _spin: Node3D
var _t := 0.0
var _done := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var is_gem := kind == "diamond"

	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.1 if is_gem else 0.7
	cs.shape = sh
	add_child(cs)

	_spin = Node3D.new()
	add_child(_spin)
	var mi := MeshInstance3D.new()
	if is_gem:
		mi.mesh = Models.diamond_mesh()
		mi.scale = Vector3.ONE * 1.3
		var mat := Models.material(Color(0.3, 0.95, 1.0), 1.5, 0.6, 0.1)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = mat
		var light := OmniLight3D.new()
		light.light_color = Color(0.4, 0.95, 1.0)
		light.omni_range = 10.0
		light.light_energy = 2.0
		add_child(light)
		# faisceau lumineux pour repérer l'objectif de loin
		var beam := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.35
		cyl.height = 60.0
		beam.mesh = cyl
		var bmat := Models.material(Color(0.4, 0.95, 1.0, 0.18), 1.0)
		bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		beam.material_override = bmat
		beam.position.y = 30.0
		add_child(beam)
		var sp := CPUParticles3D.new()
		sp.mesh = Fx.make_mesh(Color(0.6, 1.0, 1.0), 0.05)
		sp.amount = 24
		sp.lifetime = 1.6
		sp.direction = Vector3.UP
		sp.spread = 180.0
		sp.initial_velocity_min = 0.3
		sp.initial_velocity_max = 1.0
		sp.gravity = Vector3.ZERO
		sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		sp.emission_sphere_radius = 0.9
		add_child(sp)
		sp.emitting = true
	else:
		var cyl2 := CylinderMesh.new()
		cyl2.top_radius = 0.32
		cyl2.bottom_radius = 0.32
		cyl2.height = 0.08
		mi.mesh = cyl2
		mi.rotation_degrees.x = 90.0
		mi.material_override = Models.material(Color(1.0, 0.82, 0.15), 0.7, 0.8, 0.25)
	_spin.add_child(mi)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	_spin.rotation.y += delta * (1.6 if kind == "diamond" else 3.0)
	_spin.position.y = sin(_t * 2.0) * 0.15


func _on_body_entered(body) -> void:
	if _done or not body.is_in_group("player"):
		return
	_done = true
	collected.emit(kind)

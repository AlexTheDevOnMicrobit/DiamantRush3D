extends Area3D
## Projectile (canon, boss) : avance en ligne droite, repousse Lumi au contact.

const Models = preload("res://scripts/models.gd")

var velocity := Vector3.ZERO
var radius := 0.4
var life := 3.0
var color := Color(1.0, 0.25, 0.15)
var power := 9.0
var falling := false # météorite : tombe verticalement

var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = radius
	cs.shape = sh
	add_child(cs)
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 10
	sm.rings = 5
	mi.mesh = sm
	mi.material_override = Models.material(color, 2.2)
	add_child(mi)
	var l := OmniLight3D.new()
	l.light_color = color
	l.omni_range = 3.5
	l.light_energy = 1.0
	add_child(l)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	global_position += velocity * delta
	if _t >= life:
		queue_free()


func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.get_hit(global_position - velocity.normalized() * 0.5, power)
		queue_free()

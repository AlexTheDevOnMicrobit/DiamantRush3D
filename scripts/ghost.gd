extends Node3D
## Fantôme : rejoue en transparence ton meilleur passage de l'étape (échantillons à 10 Hz : x, y, z, orientation).

const Models = preload("res://scripts/models.gd")
const RATE := 10.0

var samples := PackedFloat32Array()
var best_time := 0.0
var _t := 0.0
var _model: Node3D


func _ready() -> void:
	_model = Node3D.new()
	add_child(_model)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.9, 1.0, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	body.mesh = cm
	body.material_override = mat
	body.position.y = 0.9
	_model.add_child(body)
	var visor := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.4, 0.14, 0.12)
	visor.mesh = bm
	visor.material_override = mat
	visor.position = Vector3(0, 1.5, -0.3)
	_model.add_child(visor)
	_apply(0.0)


func _process(delta: float) -> void:
	_t += delta
	_apply(_t)


func _apply(t: float) -> void:
	var n := samples.size() / 4
	if n < 2:
		visible = false
		return
	var f := t * RATE
	var i := int(f)
	if i >= n - 1:
		visible = false
		return
	visible = true
	var k := f - float(i)
	var a := Vector3(samples[i * 4], samples[i * 4 + 1], samples[i * 4 + 2])
	var b := Vector3(samples[(i + 1) * 4], samples[(i + 1) * 4 + 1], samples[(i + 1) * 4 + 2])
	global_position = a.lerp(b, k)
	_model.rotation.y = lerp_angle(samples[i * 4 + 3], samples[(i + 1) * 4 + 3], k)

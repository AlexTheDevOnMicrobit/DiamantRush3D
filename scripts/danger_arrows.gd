extends CanvasLayer
## Indicateur de danger du boss : une flèche rouge au bord de l'écran pointe vers chaque tir hors champ.

const Projectile = preload("res://scripts/projectile.gd")

var boss: Node3D = null
var player: Node = null
var _ctl: Control


func _ready() -> void:
	layer = 4
	_ctl = Control.new()
	_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ctl)
	_ctl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ctl.draw.connect(_draw_arrows)


func _process(_delta: float) -> void:
	_ctl.queue_redraw()


func _draw_arrows() -> void:
	if boss == null or not is_instance_valid(boss) or not boss.active or player == null or player.cam == null:
		return
	var cam: Camera3D = player.cam
	var size := _ctl.size
	var center := size * 0.5
	var m := 46.0
	for n in boss.get_parent().get_children():
		if not (n is Projectile):
			continue
		var pos: Vector3 = (n as Node3D).global_position
		if pos.distance_to(player.global_position) > 30.0:
			continue
		var behind := cam.is_position_behind(pos)
		var sp := cam.unproject_position(pos)
		if not behind and Rect2(Vector2(m, m), size - Vector2(m, m) * 2.0).has_point(sp):
			continue # déjà visible à l'écran
		var dir := sp - center
		if behind:
			dir = -dir
		if dir.length() < 1.0:
			dir = Vector2(0, 1)
		dir = dir.normalized()
		var k := minf((size.x * 0.5 - m) / maxf(absf(dir.x), 0.001), (size.y * 0.5 - m) / maxf(absf(dir.y), 0.001))
		var at := center + dir * k
		var side := Vector2(-dir.y, dir.x)
		var pts := PackedVector2Array([at + dir * 22.0, at - dir * 12.0 + side * 16.0, at - dir * 12.0 - side * 16.0])
		_ctl.draw_colored_polygon(pts, Color(1.0, 0.2, 0.15, 0.9))
		_ctl.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(1, 1, 1, 0.9), 2.0)

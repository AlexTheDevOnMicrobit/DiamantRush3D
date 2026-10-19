extends CanvasLayer
## Commandes tactiles : joystick flottant (gauche), bouton de saut (droite), glisser pour la caméra, bouton pause.

signal pause_pressed

var player: Node = null
var active := true

var _ctl: Control
var _scale := 1.0
var _joy_idx := -1
var _joy_origin := Vector2.ZERO
var _joy_pos := Vector2.ZERO
var _jump_idx := -1
var _cam_idx := -1
var _margins := {"left": 0, "top": 0, "right": 0, "bottom": 0}

const JOY_RADIUS := 95.0
const DEADZONE := 0.18


func _ready() -> void:
	layer = 5
	_scale = float(Global.options["touch_scale"])
	_margins = Global.safe_margins()
	_ctl = Control.new()
	_ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ctl)
	_ctl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ctl.draw.connect(_draw_ui)


func set_active(on: bool) -> void:
	active = on
	if not on:
		_release_all()
	_ctl.visible = on


func _jump_center() -> Vector2:
	var s := _ctl.size
	return Vector2(s.x - (140.0 * _scale + _margins["right"]), s.y - (130.0 * _scale + _margins["bottom"]))


func _jump_radius() -> float:
	return 78.0 * _scale


func _pause_center() -> Vector2:
	return Vector2(_ctl.size.x - (60.0 + _margins["right"]), 60.0 + _margins["top"])


func _idle_joy_center() -> Vector2:
	return Vector2(170.0 * _scale + _margins["left"], _ctl.size.y - (150.0 * _scale + _margins["bottom"]))


func _draw_ui() -> void:
	var jc := _jump_center()
	var pressed := _jump_idx != -1
	_ctl.draw_circle(jc, _jump_radius(), Color(1, 1, 1, 0.32 if pressed else 0.16))
	_ctl.draw_arc(jc, _jump_radius(), 0.0, TAU, 48, Color(1, 1, 1, 0.55), 3.0)
	_ctl.draw_string(ThemeDB.fallback_font, jc + Vector2(-34, 9) * _scale, "SAUT", HORIZONTAL_ALIGNMENT_CENTER, 68 * _scale, int(22 * _scale), Color(1, 1, 1, 0.85))

	var pc := _pause_center()
	_ctl.draw_circle(pc, 30.0, Color(0, 0, 0, 0.35))
	_ctl.draw_rect(Rect2(pc + Vector2(-10, -12), Vector2(7, 24)), Color(1, 1, 1, 0.85))
	_ctl.draw_rect(Rect2(pc + Vector2(3, -12), Vector2(7, 24)), Color(1, 1, 1, 0.85))

	var origin := _joy_origin if _joy_idx != -1 else _idle_joy_center()
	var r := JOY_RADIUS * _scale
	_ctl.draw_circle(origin, r, Color(1, 1, 1, 0.12))
	_ctl.draw_arc(origin, r, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 3.0)
	var knob := origin
	if _joy_idx != -1:
		knob = origin + (_joy_pos - origin).limit_length(r)
	_ctl.draw_circle(knob, 40.0 * _scale, Color(1, 1, 1, 0.4 if _joy_idx != -1 else 0.22))


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_touch_down(t.index, t.position)
		else:
			_touch_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_idx:
			_joy_pos = d.position
			_apply_joystick()
			_ctl.queue_redraw()
		elif d.index == _cam_idx and player:
			player.look(d.relative * 0.75)


func _touch_down(idx: int, pos: Vector2) -> void:
	if pos.distance_to(_pause_center()) < 44.0:
		pause_pressed.emit()
		return
	if pos.distance_to(_jump_center()) < _jump_radius() * 1.25 and _jump_idx == -1:
		_jump_idx = idx
		Input.action_press("jump")
		_ctl.queue_redraw()
		return
	if pos.x < _ctl.size.x * 0.45 and _joy_idx == -1:
		_joy_idx = idx
		_joy_origin = pos
		_joy_pos = pos
		_ctl.queue_redraw()
		return
	if _cam_idx == -1:
		_cam_idx = idx


func _touch_up(idx: int) -> void:
	if idx == _joy_idx:
		_joy_idx = -1
		_release_move()
	elif idx == _jump_idx:
		_jump_idx = -1
		Input.action_release("jump")
	elif idx == _cam_idx:
		_cam_idx = -1
	_ctl.queue_redraw()


func _apply_joystick() -> void:
	var v := (_joy_pos - _joy_origin) / (JOY_RADIUS * _scale)
	if v.length() > 1.0:
		v = v.normalized()
	if v.length() < DEADZONE:
		_release_move()
		return
	_set_axis("right", maxf(v.x, 0.0))
	_set_axis("left", maxf(-v.x, 0.0))
	_set_axis("back", maxf(v.y, 0.0))
	_set_axis("forward", maxf(-v.y, 0.0))


func _set_axis(action: String, strength: float) -> void:
	if strength > 0.01:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _release_move() -> void:
	for a in ["left", "right", "forward", "back"]:
		Input.action_release(a)


func _release_all() -> void:
	_release_move()
	Input.action_release("jump")
	_joy_idx = -1
	_jump_idx = -1
	_cam_idx = -1
	if is_instance_valid(_ctl):
		_ctl.queue_redraw()


func _exit_tree() -> void:
	_release_all()

extends CanvasLayer
## Couche d'interface qui reste active pendant la pause.

signal pause_toggled
signal photo_shot


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_toggled.emit()
	elif event.is_action_pressed("jump") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER):
		photo_shot.emit()

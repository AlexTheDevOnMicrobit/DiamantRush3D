extends CanvasLayer
## Couche d'interface qui reste active pendant la pause.

signal pause_toggled


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_toggled.emit()

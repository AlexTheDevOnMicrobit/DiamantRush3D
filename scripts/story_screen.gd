extends Control
## Écran d'histoire avec texte qui s'écrit. Espace / Entrée / clic = accélérer puis continuer.

const UI = preload("res://scripts/ui.gd")
const LevelData = preload("res://scripts/level_data.gd")

var info: Dictionary
var text_label: Label
var tween: Tween
var done_typing := false
var leaving := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	info = Global.pending_story
	if info.is_empty():
		info = {"title": "", "text": "", "theme": 0, "next": "menu", "button": "Continuer"}
	var theme: Dictionary = LevelData.get_themes()[clampi(int(info["theme"]), 0, LevelData.WORLD_COUNT - 1)]
	Global.stop_music()

	var bg := ColorRect.new()
	bg.color = Color(theme["sky_top"]).darkened(0.3)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var glow := ColorRect.new()
	glow.color = Color(Color(theme["sky_horizon"]), 0.35)
	glow.anchor_top = 0.55
	glow.anchor_right = 1.0
	glow.anchor_bottom = 1.0
	add_child(glow)

	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var pn := UI.panel()
	center.add_child(pn)
	var vb := UI.vbox(18)
	pn.add_child(vb)
	vb.add_child(UI.label(String(info["title"]), 44, Color.GOLD, HORIZONTAL_ALIGNMENT_CENTER))

	text_label = UI.label(String(info["text"]), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(760, 0)
	text_label.visible_ratio = 0.0
	vb.add_child(text_label)

	var row := CenterContainer.new()
	row.add_child(UI.button(String(info["button"]), _continue))
	vb.add_child(row)
	vb.add_child(UI.label("Espace / Entrée / toucher l'écran : continuer", 16, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER))

	var dur := clampf(String(info["text"]).length() * 0.025, 1.0, 9.0)
	tween = create_tween()
	tween.tween_property(text_label, "visible_ratio", 1.0, dur)
	tween.finished.connect(func(): done_typing = true)


func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventKey and event.pressed and not event.echo:
		pressed = event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	elif event is InputEventMouseButton and event.pressed:
		pressed = true
	if pressed:
		_continue()


func _continue() -> void:
	if leaving:
		return
	if not done_typing:
		if tween:
			tween.kill()
		text_label.visible_ratio = 1.0
		done_typing = true
		return
	leaving = true
	Global.play_sfx("click")
	Global.save_game()
	match String(info["next"]):
		"stage_story":
			Global.show_stage_story()
		"level":
			get_tree().change_scene_to_file("res://scenes/level.tscn")
		_:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

extends RefCounted
## Petits helpers pour construire l'interface par code.


static func label(text: String, size: int = 22, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", int(size * float(Global.options["text_scale"])))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	return l


static func button(text: String, cb: Callable, min_size: Vector2 = Vector2(340, 54)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.pressed.connect(cb)
	return b


static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.16, 0.92)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(28)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.5, 0.8, 1.0, 0.5)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func vbox(sep: int = 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

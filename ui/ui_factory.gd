class_name UIFactory
extends RefCounted
## 所有界面通过这里创建控件，保证视觉一致。

static func panel_style(bg: Color, radius: int = 20, shadow: int = 10,
		shadow_color: Color = Color(0, 0, 0, 0.12)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if shadow > 0:
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.4)
		s.shadow_color = shadow_color
	return s

static func make_label(text: String, font_size: int = 20,
		color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

static func style_button(btn: Button, base: Color, font_size: int = 22,
		text_color: Color = Color("#3D3D3D"), radius: int = 16,
		shadow_color: Color = Color(0, 0, 0, 0.12)) -> void:
	btn.add_theme_font_size_override("font_size", font_size)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(state, text_color)
	btn.add_theme_stylebox_override("normal", panel_style(base, radius, 6, shadow_color))
	btn.add_theme_stylebox_override("hover", panel_style(base.lightened(0.10), radius, 9, shadow_color))
	btn.add_theme_stylebox_override("pressed", panel_style(base.darkened(0.08), radius, 2, shadow_color))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var dis := panel_style(base.lerp(Color(0.6, 0.6, 0.6), 0.55), radius, 2, shadow_color)
	btn.add_theme_stylebox_override("disabled", dis)
	btn.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.35, 0.7))

static func make_button(text: String, base: Color, font_size: int = 22,
		min_size: Vector2 = Vector2(260, 64),
		text_color: Color = Color("#3D3D3D")) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	style_button(b, base, font_size, text_color)
	return b

static func make_backdrop(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

static func make_vbox(sep: int = 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func make_hbox(sep: int = 16) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h
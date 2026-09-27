extends CanvasLayer
## 屏幕右上角的轻量提示条。

var _container: VBoxContainer

func _ready() -> void:
	layer = 128

	_container = VBoxContainer.new()
	_container.anchor_left = 1.0
	_container.anchor_top = 0.0
	_container.anchor_right = 1.0
	_container.anchor_bottom = 0.0
	_container.offset_left = -400.0
	_container.offset_right = -20.0
	_container.offset_top = 20.0
	_container.offset_bottom = 500.0
	_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_container.grow_vertical = Control.GROW_DIRECTION_END
	_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_theme_constant_override("separation", 10)
	add_child(_container)

	EventBus.request_toast.connect(_on_toast)
	EventBus.achievement_unlocked.connect(_on_achievement)

func _on_toast(text: String, kind: int) -> void:
	spawn(text, kind)

func _on_achievement(id: String) -> void:
	var info := AchievementManager.info(id)
	spawn("🏆 " + info.get("name", id), 1)

func spawn(text: String, kind: int = 0) -> void:
	var panel := PanelContainer.new()
	var bg := ThemeManager.color("card")
	if kind == 1:
		bg = ThemeManager.color("accent")
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	sb.shadow_color = ThemeManager.color("shadow")
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", ThemeManager.scaled(18))
	lbl.add_theme_color_override("font_color", ThemeManager.color("text"))
	panel.add_child(lbl)

	_container.add_child(panel)

	panel.modulate.a = 0.0
	# 注意：panel 由 VBoxContainer 负责布局，直接补间 position 会被容器每帧覆盖，
	# 因此只做淡入动画。
	var t_in := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_in.tween_property(panel, "modulate:a", 1.0, 0.22)

	var t_out := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t_out.tween_interval(2.6)
	t_out.tween_property(panel, "modulate:a", 0.0, 0.35)
	t_out.tween_callback(panel.queue_free)
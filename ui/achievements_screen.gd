extends Control

func _ready() -> void:
	_build()

func _build() -> void:
	add_child(UIFactory.make_backdrop(ThemeManager.color("bg")))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		UIFactory.panel_style(ThemeManager.color("card"), 28, 16, ThemeManager.color("shadow")))
	center.add_child(card)

	var margin := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 28)
	card.add_child(margin)

	var vb := UIFactory.make_vbox(14)
	margin.add_child(vb)

	var title := UIFactory.make_label(
		"成就 %d / %d" % [AchievementManager.unlocked_count(), AchievementManager.total_count()],
		ThemeManager.scaled(32), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var list := UIFactory.make_vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for a in AchievementManager.ACHIEVEMENTS:
		list.add_child(_make_entry(a))

	var back := UIFactory.make_button("返回", ThemeManager.color("card_alt"),
		ThemeManager.scaled(20), Vector2(220, 56), ThemeManager.color("text"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): TransitionManager.change_scene(Constants.SCENE_MAIN_MENU))
	vb.add_child(back)

func _make_entry(a: Dictionary) -> PanelContainer:
	var unlocked := AchievementManager.is_unlocked(a["id"])
	var bg: Color = ThemeManager.color("accent") if unlocked else ThemeManager.color("card_alt")

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		UIFactory.panel_style(bg, 16, 4, ThemeManager.color("shadow")))
	panel.custom_minimum_size = Vector2(0, 72)

	var margin := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 14)
	panel.add_child(margin)

	var row := UIFactory.make_hbox(14)
	margin.add_child(row)

	var icon := UIFactory.make_label(a["icon"], ThemeManager.scaled(28), ThemeManager.color("text"))
	icon.custom_minimum_size = Vector2(44, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var info := UIFactory.make_vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var name_l := UIFactory.make_label(a["name"], ThemeManager.scaled(20), ThemeManager.color("text"))
	info.add_child(name_l)

	var desc := UIFactory.make_label(a["desc"], ThemeManager.scaled(15), ThemeManager.color("text_dim"))
	info.add_child(desc)

	var state := UIFactory.make_label("已解锁" if unlocked else "未解锁",
		ThemeManager.scaled(16), ThemeManager.color("text"))
	row.add_child(state)

	if not unlocked:
		panel.modulate = Color(1, 1, 1, 0.72)

	return panel
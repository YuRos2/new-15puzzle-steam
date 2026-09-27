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

	var vb := UIFactory.make_vbox(16)
	margin.add_child(vb)

	var title := UIFactory.make_label("设置", ThemeManager.scaled(36), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(620, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var list := UIFactory.make_vbox(14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	_add_section(list, "音频")
	_add_slider(list, "主音量", "master_volume", 0.0, 1.0, 0.05)
	_add_slider(list, "音乐音量", "music_volume", 0.0, 1.0, 0.05)
	_add_slider(list, "音效音量", "sfx_volume", 0.0, 1.0, 0.05)
	_add_toggle(list, "静音", "mute")

	_add_section(list, "外观")
	_add_option(list, "界面主题", "theme", ["浅色", "深色", "高对比"], [0, 1, 2])
	_add_option(list, "方块样式", "tile_style", ["数字", "汉字", "符号"], [0, 1, 2])
	_add_slider(list, "字体缩放", "font_scale", 0.8, 1.4, 0.05, true)

	_add_section(list, "体验")
	_add_toggle(list, "减少动画", "reduce_motion")
	_add_toggle(list, "显示计时器", "show_timer")
	_add_toggle(list, "重开前确认", "confirm_restart")
	_add_toggle(list, "方向键操作", "keyboard_control")

	var replay := UIFactory.make_button("重新显示玩法引导", ThemeManager.color("accent2"),
		ThemeManager.scaled(18), Vector2(240, 52), ThemeManager.color("text"))
	replay.pressed.connect(func():
		SettingsManager.set_value("tutorial_seen", false)
		EventBus.request_toast.emit("下次进入拼图时会重新显示引导", 0)
	)
	list.add_child(replay)

	_add_section(list, "数据")
	var reset := UIFactory.make_button("重置全部数据", Color("#FFB7B2"),
		ThemeManager.scaled(18), Vector2(240, 52), ThemeManager.color("text"))
	reset.pressed.connect(_on_reset)
	list.add_child(reset)

	var back := UIFactory.make_button("返回", ThemeManager.color("card_alt"),
		ThemeManager.scaled(20), Vector2(220, 56), ThemeManager.color("text"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): TransitionManager.change_scene(Constants.SCENE_MAIN_MENU))
	vb.add_child(back)

func _add_section(parent: VBoxContainer, text: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	parent.add_child(spacer)
	var l := UIFactory.make_label(text, ThemeManager.scaled(20), ThemeManager.color("accent"))
	parent.add_child(l)
	var line := HSeparator.new()
	parent.add_child(line)

func _add_slider(parent: VBoxContainer, label: String, key: String,
		min_v: float, max_v: float, step: float, percent: bool = false) -> void:
	var row := UIFactory.make_hbox(16)
	parent.add_child(row)

	var l := UIFactory.make_label(label, ThemeManager.scaled(18), ThemeManager.color("text"))
	l.custom_minimum_size = Vector2(160, 0)
	row.add_child(l)

	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = SettingsManager.get_float(key)
	slider.custom_minimum_size = Vector2(280, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)

	var vl := UIFactory.make_label(_fmt_val(slider.value, percent),
		ThemeManager.scaled(16), ThemeManager.color("text_dim"))
	vl.custom_minimum_size = Vector2(70, 0)
	row.add_child(vl)

	slider.value_changed.connect(func(v: float):
		SettingsManager.set_value(key, v)
		vl.text = _fmt_val(v, percent)
	)

func _fmt_val(v: float, _percent: bool = false) -> String:
	return "%d%%" % int(round(v * 100.0))

func _add_toggle(parent: VBoxContainer, label: String, key: String) -> void:
	var row := UIFactory.make_hbox(16)
	parent.add_child(row)

	var l := UIFactory.make_label(label, ThemeManager.scaled(18), ThemeManager.color("text"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)

	var check := CheckButton.new()
	check.button_pressed = SettingsManager.get_bool(key)
	check.focus_mode = Control.FOCUS_NONE
	row.add_child(check)

	check.toggled.connect(func(on: bool): SettingsManager.set_value(key, on))

func _add_option(parent: VBoxContainer, label: String, key: String,
		names: Array, values: Array) -> void:
	var row := UIFactory.make_hbox(16)
	parent.add_child(row)

	var l := UIFactory.make_label(label, ThemeManager.scaled(18), ThemeManager.color("text"))
	l.custom_minimum_size = Vector2(160, 0)
	row.add_child(l)

	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.custom_minimum_size = Vector2(200, 40)
	for i in range(names.size()):
		ob.add_item(str(names[i]), int(values[i]))
	var cur := SettingsManager.get_int(key)
	for i in range(ob.item_count):
		if ob.get_item_id(i) == cur:
			ob.select(i)
			break
	row.add_child(ob)

	ob.item_selected.connect(func(i: int):
		SettingsManager.set_value(key, ob.get_item_id(i))
	)

func _on_reset() -> void:
	# 两步确认：避免孩子误点把统计、成就和存档全部清空。
	var first := ConfirmationDialog.new()
	first.dialog_text = "这会清空所有统计、成就与存档，确定吗？"
	first.title = "重置数据 · 第 1 步"
	first.ok_button_text = "继续"
	first.cancel_button_text = "取消"
	add_child(first)
	first.confirmed.connect(func():
		first.queue_free()
		_confirm_reset_second()
	)
	first.canceled.connect(func(): first.queue_free())
	first.close_requested.connect(func(): first.queue_free())
	first.popup_centered()

func _confirm_reset_second() -> void:
	var second := ConfirmationDialog.new()
	second.dialog_text = "请再确认一次：所有记录将无法恢复。"
	second.title = "重置数据 · 第 2 步"
	second.ok_button_text = "确认清空"
	second.cancel_button_text = "我再想想"
	add_child(second)
	second.confirmed.connect(func():
		SaveManager.wipe_all()
		get_tree().reload_current_scene()
	)
	second.canceled.connect(func(): second.queue_free())
	second.close_requested.connect(func(): second.queue_free())
	second.popup_centered()

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

	var title := UIFactory.make_label("统计", ThemeManager.scaled(34), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 440)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	var list := UIFactory.make_vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var total := int(StatsManager.get_stat("total_games"))
	var wins := int(StatsManager.get_stat("wins"))
	var losses := int(StatsManager.get_stat("losses"))

	list.add_child(_section("总览"))
	list.add_child(_row("总对局", "%d" % total))
	list.add_child(_row("通关", "%d" % wins))
	list.add_child(_row("失败", "%d" % losses))
	list.add_child(_row("胜率", "%.1f%%" % (StatsManager.win_rate() * 100.0)))
	list.add_child(_row("平均步数", "%.1f" % StatsManager.average_steps()))
	list.add_child(_row("平均用时", _fmt(StatsManager.average_time())))
	list.add_child(_row("最长连胜", "%d" % int(StatsManager.get_stat("best_streak"))))
	list.add_child(_row("每日挑战完成", "%d 次" % int(StatsManager.get_stat("daily_completed"))))

	list.add_child(_section("各模式最佳记录"))
	for mode in Constants.MODE_INFO.keys():
		for size in Constants.BOARD_SIZES:
			var rec := StatsManager.get_record(mode, size)
			var bs := int(rec["best_steps"])
			if bs < 0:
				continue
			list.add_child(_row("%s · %d×%d" % [Constants.mode_name(mode), size, size],
				"%d 步 · %s" % [bs, _fmt(float(rec["best_time"]))]))

	list.add_child(_section("最近对局"))
	var recent: Array = StatsManager.get_stat("recent")
	if recent.is_empty():
		list.add_child(_row("—", "还没有对局记录"))
	else:
		for i in range(mini(recent.size(), 12)):
			var r: Dictionary = recent[i]
			var mark := "✔" if bool(r["won"]) else "✘"
			list.add_child(_row(
				"%s %s · %d×%d" % [mark, Constants.mode_name(int(r["mode"])),
					int(r["size"]), int(r["size"])],
				"%d 步 · %s" % [int(r["steps"]), _fmt(float(r["time"]))]))

	var back := UIFactory.make_button("返回", ThemeManager.color("card_alt"),
		ThemeManager.scaled(20), Vector2(220, 56), ThemeManager.color("text"))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): TransitionManager.change_scene(Constants.SCENE_MAIN_MENU))
	vb.add_child(back)

func _section(text: String) -> Label:
	return UIFactory.make_label(text, ThemeManager.scaled(20), ThemeManager.color("accent"))

func _row(label: String, value: String) -> HBoxContainer:
	var row := UIFactory.make_hbox(16)
	var l := UIFactory.make_label(label, ThemeManager.scaled(17), ThemeManager.color("text_dim"))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var v := UIFactory.make_label(value, ThemeManager.scaled(17), ThemeManager.color("text"))
	row.add_child(v)
	return row

func _fmt(t: float) -> String:
	if t <= 0.0:
		return "--:--"
	return Constants.fmt_time(t)
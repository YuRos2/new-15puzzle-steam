extends Control

func _ready() -> void:
	_build()
	_animate()

func _build() -> void:
	var res := GameSession.last_result
	var won := bool(res.get("won", true))
	var steps := int(res.get("steps", 0))
	var time_s := float(res.get("time", 0.0))
	var stars := int(res.get("stars", 0))
	var optimal := int(res.get("optimal", -1))
	var mode := int(res.get("mode", 0))
	var size := int(res.get("size", 4))
	var changes: Dictionary = GameSession.stats_changes

	add_child(UIFactory.make_backdrop(ThemeManager.color("bg")))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		UIFactory.panel_style(ThemeManager.color("card"), 30, 18, ThemeManager.color("shadow")))
	center.add_child(card)

	var margin := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 32)
	card.add_child(margin)

	var vb := UIFactory.make_vbox(14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vb)

	var title := UIFactory.make_label("🎉 太棒了！" if won else "挑战结束",
		ThemeManager.scaled(48), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sub := UIFactory.make_label("%s · %d×%d" % [Constants.mode_name(mode), size, size],
		ThemeManager.scaled(18), ThemeManager.color("text_dim"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var star_label := UIFactory.make_label(Constants.star_text(stars),
		ThemeManager.scaled(46), ThemeManager.color("accent"))
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(star_label)

	vb.add_child(_stat_row("步数", "%d" % steps))
	vb.add_child(_stat_row("用时", _fmt(time_s)))
	if optimal > 0:
		vb.add_child(_stat_row("最优解", "%d 步" % optimal))

	if bool(changes.get("new_best_steps", false)) or bool(changes.get("new_best_time", false)):
		var nb := UIFactory.make_label("🎉 打破个人纪录！", ThemeManager.scaled(20),
			ThemeManager.color("accent"))
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(nb)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vb.add_child(gap)

	# ── 按钮组 ──
	var row := UIFactory.make_hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)

	var retry := UIFactory.make_button("再来一局", ThemeManager.color("accent"),
		ThemeManager.scaled(20), Vector2(180, 56), ThemeManager.color("text"))
	retry.pressed.connect(_on_retry)
	row.add_child(retry)

	if mode == Constants.Mode.ENDLESS:
		var next := UIFactory.make_button("下一关", ThemeManager.color("accent4"),
			ThemeManager.scaled(20), Vector2(180, 56), ThemeManager.color("text"))
		next.pressed.connect(_on_next_endless)
		row.add_child(next)

	var menu := UIFactory.make_button("返回主菜单", ThemeManager.color("card_alt"),
		ThemeManager.scaled(20), Vector2(200, 56), ThemeManager.color("text"))
	menu.pressed.connect(_on_menu)
	row.add_child(menu)

func _stat_row(label: String, value: String) -> HBoxContainer:
	var row := UIFactory.make_hbox(24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var l := UIFactory.make_label(label, ThemeManager.scaled(20), ThemeManager.color("text_dim"))
	l.custom_minimum_size = Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(l)
	var v := UIFactory.make_label(value, ThemeManager.scaled(22), ThemeManager.color("text"))
	v.custom_minimum_size = Vector2(160, 0)
	row.add_child(v)
	return row

func _animate() -> void:
	modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.28)

func _fmt(t: float) -> String:
	return Constants.fmt_time(t)

func _on_retry() -> void:
	GameSession.new_board()
	GameSession.steps = 0
	GameSession.elapsed = 0.0
	GameSession.used_undo = false
	TransitionManager.change_scene(Constants.SCENE_GAME)

func _on_next_endless() -> void:
	var next_size: int = GameSession.size
	if GameSession.size < 6:
		next_size += 1
	GameSession.configure(Constants.Mode.ENDLESS, next_size, {"streak": GameSession.streak + 1})
	TransitionManager.change_scene(Constants.SCENE_GAME)

func _on_menu() -> void:
	GameSession.clear()
	TransitionManager.change_scene(Constants.SCENE_MAIN_MENU)
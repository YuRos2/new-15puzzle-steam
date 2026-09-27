extends Control

var _continue_btn: Button
var _buttons: Array[Button] = []
var _title: Label
var _summary: Label

func _ready() -> void:
	_build()
	_refresh()
	_play_entry_animation()

func _build() -> void:
	add_child(UIFactory.make_backdrop(ThemeManager.color("bg")))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := UIFactory.make_vbox(14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vb)

	_title = UIFactory.make_label("数字华容道", ThemeManager.scaled(62), ThemeManager.color("text"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)

	var sub := UIFactory.make_label("NUMBER KLOTSKI", ThemeManager.scaled(16), ThemeManager.color("text_dim"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	_summary = UIFactory.make_label("", ThemeManager.scaled(16), ThemeManager.color("text_dim"))
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_summary)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	vb.add_child(gap)

	_continue_btn = _add_button(vb, "继续游戏", ThemeManager.color("accent2"), _on_continue)
	_add_button(vb, "开始游戏", ThemeManager.color("accent"), _on_play)
	_add_button(vb, "每日挑战", ThemeManager.color("accent4"), _on_daily)

	var row := UIFactory.make_hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(row)
	_add_button(row, "统计", ThemeManager.color("accent3"), _on_stats, Vector2(140, 58), 20)
	_add_button(row, "成就", ThemeManager.color("accent5"), _on_achievements, Vector2(140, 58), 20)
	_add_button(row, "设置", ThemeManager.color("card_alt"), _on_settings, Vector2(140, 58), 20)

	_add_button(vb, "退出游戏", ThemeManager.color("card_alt"), _on_quit)

func _add_button(parent: Node, text: String, color: Color, cb: Callable,
		min_size: Vector2 = Vector2(300, 64), font_size: int = 24) -> Button:
	var b := UIFactory.make_button(text, color, ThemeManager.scaled(font_size), min_size,
		ThemeManager.color("text"))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	parent.add_child(b)
	_buttons.append(b)
	return b

func _refresh() -> void:
	_continue_btn.visible = GameSession.has_saved_session()
	var total := int(StatsManager.get_stat("total_games"))
	var wins := int(StatsManager.get_stat("wins"))
	var best := int(StatsManager.get_stat("best_streak"))
	var unlocked := AchievementManager.unlocked_count()
	if total > 0:
		_summary.text = "已挑战 %d 局 · 通关 %d · 最长连胜 %d · 成就 %d/%d" % [
			total, wins, best, unlocked, AchievementManager.total_count()]
	else:
		_summary.text = "选一个模式，开始玩吧！"

func _play_entry_animation() -> void:
	if _title:
		_title.modulate.a = 0.0
		var t := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(_title, "modulate:a", 1.0, 0.45)

	var delay := 0.10
	for b in _buttons:
		b.modulate.a = 0.0
		var t := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_interval(delay)
		t.tween_property(b, "modulate:a", 1.0, 0.32)
		delay += 0.06

func _on_continue() -> void:
	if GameSession.load_saved():
		TransitionManager.change_scene(Constants.SCENE_GAME)
	else:
		EventBus.request_toast.emit("没有可继续的对局", 0)

func _on_play() -> void:
	AudioManager.play_sfx("click")
	TransitionManager.change_scene(Constants.SCENE_MODE_SELECT)

func _on_daily() -> void:
	AudioManager.play_sfx("click")
	GameSession.configure(Constants.Mode.DAILY, 4)
	TransitionManager.change_scene(Constants.SCENE_GAME)

func _on_stats() -> void:
	TransitionManager.change_scene(Constants.SCENE_STATS)

func _on_achievements() -> void:
	TransitionManager.change_scene(Constants.SCENE_ACHIEVEMENTS)

func _on_settings() -> void:
	TransitionManager.change_scene(Constants.SCENE_SETTINGS)

func _on_quit() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "确定要退出游戏吗？下次打开还能继续玩哦。"
	dlg.title = "退出游戏"
	dlg.ok_button_text = "退出"
	dlg.cancel_button_text = "继续玩"
	add_child(dlg)
	dlg.confirmed.connect(func():
		SaveManager.save_now()
		get_tree().quit()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.close_requested.connect(func(): dlg.queue_free())
	dlg.popup_centered()
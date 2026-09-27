extends Control

var _mode: int = Constants.Mode.CLASSIC
var _size: int = 4

var _mode_buttons: Dictionary = {}
var _size_buttons: Dictionary = {}
var _desc_label: Label
var _record_label: Label
var _start_btn: Button

func _ready() -> void:
	_build()
	_select_mode(Constants.Mode.CLASSIC)
	_select_size(Constants.RECOMMENDED_SIZE)

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

	var title := UIFactory.make_label("选择模式", ThemeManager.scaled(38), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)

	for m in Constants.MODE_INFO.keys():
		var info: Dictionary = Constants.MODE_INFO[m]
		var b := UIFactory.make_button(info["name"], Color(info["color"]),
			ThemeManager.scaled(20), Vector2(230, 58), ThemeManager.color("text"))
		b.pressed.connect(func(): _select_mode(m))
		grid.add_child(b)
		_mode_buttons[m] = b

	_desc_label = UIFactory.make_label("", ThemeManager.scaled(16), ThemeManager.color("text_dim"))
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.custom_minimum_size = Vector2(0, 26)
	vb.add_child(_desc_label)

	var size_title := UIFactory.make_label("棋盘大小", ThemeManager.scaled(20), ThemeManager.color("text"))
	vb.add_child(size_title)

	var size_hint := UIFactory.make_label("第一次玩建议从「入门」开始，熟悉后再挑战更大的棋盘",
		ThemeManager.scaled(15), ThemeManager.color("text_dim"))
	size_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(size_hint)

	var size_row := UIFactory.make_hbox(10)
	size_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(size_row)

	for s in Constants.BOARD_SIZES:
		var col := UIFactory.make_vbox(4)
		size_row.add_child(col)

		var b := UIFactory.make_button("%d×%d" % [s, s], ThemeManager.color("card_alt"),
			ThemeManager.scaled(20), Vector2(110, 54), ThemeManager.color("text"))
		b.pressed.connect(func(): _select_size(s))
		col.add_child(b)
		_size_buttons[s] = b

		var tag := Constants.size_label(s)
		if s == Constants.RECOMMENDED_SIZE:
			tag += " ⭐推荐"
		var tag_label := UIFactory.make_label(tag, ThemeManager.scaled(14), ThemeManager.color("text_dim"))
		tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(tag_label)

	_record_label = UIFactory.make_label("", ThemeManager.scaled(16), ThemeManager.color("text_dim"))
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.custom_minimum_size = Vector2(0, 26)
	vb.add_child(_record_label)

	var btn_row := UIFactory.make_hbox(14)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(btn_row)

	var back := UIFactory.make_button("返回", ThemeManager.color("card_alt"),
		ThemeManager.scaled(22), Vector2(180, 60), ThemeManager.color("text"))
	back.pressed.connect(func(): TransitionManager.change_scene(Constants.SCENE_MAIN_MENU))
	btn_row.add_child(back)

	_start_btn = UIFactory.make_button("开始挑战", ThemeManager.color("accent"),
		ThemeManager.scaled(22), Vector2(220, 60), ThemeManager.color("text"))
	_start_btn.pressed.connect(_on_start)
	btn_row.add_child(_start_btn)

func _select_mode(m: int) -> void:
	_mode = m
	AudioManager.play_sfx("click")
	for k in _mode_buttons:
		var b: Button = _mode_buttons[k]
		var base := Color(Constants.MODE_INFO[k]["color"])
		if k == m:
			b.modulate = Color.WHITE
			UIFactory.style_button(b, base, ThemeManager.scaled(20), ThemeManager.color("text"), 16)
			b.custom_minimum_size = Vector2(230, 62)
		else:
			b.modulate = Color(1, 1, 1, 0.55)
			UIFactory.style_button(b, base, ThemeManager.scaled(20), ThemeManager.color("text"), 16)
			b.custom_minimum_size = Vector2(230, 58)
	_desc_label.text = Constants.mode_desc(m)
	_refresh_record()

func _select_size(s: int) -> void:
	_size = s
	AudioManager.play_sfx("click")
	for k in _size_buttons:
		var b: Button = _size_buttons[k]
		if k == s:
			UIFactory.style_button(b, ThemeManager.color("accent"), ThemeManager.scaled(20),
				ThemeManager.color("text"), 16)
		else:
			UIFactory.style_button(b, ThemeManager.color("card_alt"), ThemeManager.scaled(20),
				ThemeManager.color("text"), 16)
	_refresh_record()

func _refresh_record() -> void:
	var rec := StatsManager.get_record(_mode, _size)
	var bs := int(rec["best_steps"])
	var bt := float(rec["best_time"])
	if bs < 0:
		_record_label.text = "该难度暂无记录"
	else:
		_record_label.text = "最佳：%d 步 · %s" % [bs, _fmt_time(bt)]

func _fmt_time(t: float) -> String:
	return Constants.fmt_time(t)

func _on_start() -> void:
	AudioManager.play_sfx("click")
	GameSession.configure(_mode, _size)
	TransitionManager.change_scene(Constants.SCENE_GAME)
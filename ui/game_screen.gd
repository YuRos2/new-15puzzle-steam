extends Control

const GAP := 10.0
const BOARD_MAX := 430.0
const CELL_MAX := 110.0
const HISTORY_LIMIT := 80

var _mode: int = Constants.Mode.CLASSIC
var _size: int = 4
var _board: PuzzleBoard
var _steps: int = 0
var _elapsed: float = 0.0
var _is_running: bool = false
var _is_finished: bool = false
# 只记录每步移动前空位的位置，撤销时反向移动即可还原，
# 无需每步克隆整张棋盘（省内存、避免频繁分配）。
var _history: Array[int] = []
var _undo_used: bool = false

var _memory_reveal: bool = false
var _memory_timer: float = 0.0

var _streak: int = 0

var _board_area: Control
var _tile_nodes: Dictionary = {}
var _cell: float = 100.0
var _origin: Vector2 = Vector2.ZERO
var _move_tween: Tween
var _daily_key: String = ""

var _steps_label: Label
var _timer_label: Label
var _mode_label: Label
var _limit_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _undo_btn: Button
var _hint_btn: Button
var _restart_btn: Button
var _back_btn: Button
var _help_btn: Button

var _hud_accum: float = 0.0

# 面向中小学生的引导：首次进入时教学，之后可随时点“玩法”重看。
var _tutorial_overlay: Control = null
var _tutorial_first_time: bool = false
var _tutorial_waiting_first_move: bool = false
# 每 25% 给一次鼓励，只往前走，撤销不会重复提示。
var _progress_milestone: int = 0

func _ready() -> void:
	_mode = GameSession.mode
	_size = GameSession.size
	_streak = GameSession.streak
	if GameSession.board == null:
		GameSession.new_board()
	_board = GameSession.board

	_steps = GameSession.steps
	_elapsed = GameSession.elapsed
	_undo_used = GameSession.used_undo
	if _mode == Constants.Mode.DAILY:
		_daily_key = PuzzleGenerator.today_key()

	# 记忆模式需先亮出数字再创建方块，否则首次进入时数字会是空的。
	if _mode == Constants.Mode.MEMORY:
		_memory_reveal = true
		_memory_timer = Constants.MEMORY_SHOW_SECONDS
	else:
		_memory_reveal = false

	_build_ui()
	_create_tiles()
	_update_hud()

	if _mode == Constants.Mode.MEMORY:
		_toast("👀 先记住数字的位置！%.0f 秒后它们会藏起来" % Constants.MEMORY_SHOW_SECONDS)

	# 首次进入先看引导；引导期间暂停计时与操作，避免手忙脚乱。
	if not SettingsManager.get_bool("tutorial_seen"):
		_is_running = false
		_show_tutorial(true)
	else:
		_is_running = true
	_is_finished = false

func _build_ui() -> void:
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
		margin.add_theme_constant_override("margin_" + s, 22)
	card.add_child(margin)

	var vb := UIFactory.make_vbox(14)
	margin.add_child(vb)

	var top := UIFactory.make_hbox(16)
	vb.add_child(top)

	_back_btn = UIFactory.make_button("← 返回", ThemeManager.color("card_alt"),
		ThemeManager.scaled(18), Vector2(110, 46), ThemeManager.color("text"))
	_back_btn.pressed.connect(_on_back)
	top.add_child(_back_btn)

	_mode_label = UIFactory.make_label(Constants.mode_name(_mode),
		ThemeManager.scaled(18), ThemeManager.color("text_dim"))
	top.add_child(_mode_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)

	_steps_label = UIFactory.make_label("步数 0", ThemeManager.scaled(20), ThemeManager.color("text"))
	top.add_child(_steps_label)

	_timer_label = UIFactory.make_label("00:00", ThemeManager.scaled(20), ThemeManager.color("text"))
	_timer_label.visible = SettingsManager.get_bool("show_timer")
	top.add_child(_timer_label)

	# 面向低龄玩家的一行玩法提示，始终可见、语气友好。
	var goal := UIFactory.make_label("👉 把 1～%d 从小到大排好，空位放在最后" % (_size * _size - 1),
		ThemeManager.scaled(17), ThemeManager.color("text_dim"))
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(goal)

	_board_area = Control.new()
	_board_area.custom_minimum_size = Vector2(BOARD_MAX, BOARD_MAX)
	_board_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_board_area)

	# 完成度进度条：让孩子随时看到“离成功还有多远”。
	var progress_row := UIFactory.make_hbox(12)
	progress_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(progress_row)

	_progress_label = UIFactory.make_label("完成度 0%", ThemeManager.scaled(17), ThemeManager.color("text_dim"))
	_progress_label.custom_minimum_size = Vector2(112, 0)
	progress_row.add_child(_progress_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(BOARD_MAX - 130, 16)
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_bar.show_percentage = false
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	var p_bg := StyleBoxFlat.new()
	p_bg.bg_color = ThemeManager.color("card_alt")
	p_bg.corner_radius_top_left = 8
	p_bg.corner_radius_top_right = 8
	p_bg.corner_radius_bottom_left = 8
	p_bg.corner_radius_bottom_right = 8
	var p_fg := StyleBoxFlat.new()
	p_fg.bg_color = ThemeManager.color("accent2")
	p_fg.corner_radius_top_left = 8
	p_fg.corner_radius_top_right = 8
	p_fg.corner_radius_bottom_left = 8
	p_fg.corner_radius_bottom_right = 8
	_progress_bar.add_theme_stylebox_override("background", p_bg)
	_progress_bar.add_theme_stylebox_override("fill", p_fg)
	progress_row.add_child(_progress_bar)

	var bottom := UIFactory.make_hbox(14)
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(bottom)

	_undo_btn = UIFactory.make_button("↩ 撤销", ThemeManager.color("accent2"),
		ThemeManager.scaled(18), Vector2(130, 50), ThemeManager.color("text"))
	_undo_btn.pressed.connect(_on_undo)
	bottom.add_child(_undo_btn)

	_hint_btn = UIFactory.make_button("💡 提示", ThemeManager.color("accent4"),
		ThemeManager.scaled(18), Vector2(130, 50), ThemeManager.color("text"))
	_hint_btn.pressed.connect(_on_hint)
	bottom.add_child(_hint_btn)

	_restart_btn = UIFactory.make_button("🔄 重开", ThemeManager.color("accent5"),
		ThemeManager.scaled(18), Vector2(130, 50), ThemeManager.color("text"))
	_restart_btn.pressed.connect(_on_restart)
	bottom.add_child(_restart_btn)

	_help_btn = UIFactory.make_button("❓ 玩法", ThemeManager.color("card_alt"),
		ThemeManager.scaled(18), Vector2(130, 50), ThemeManager.color("text"))
	_help_btn.pressed.connect(func(): _show_tutorial(false))
	bottom.add_child(_help_btn)

	_limit_label = UIFactory.make_label("", ThemeManager.scaled(16), ThemeManager.color("text_dim"))
	_limit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_limit_label)

func _create_tiles() -> void:
	for c in _board_area.get_children():
		c.queue_free()
	_tile_nodes.clear()

	_cell = minf(CELL_MAX, (BOARD_MAX - GAP * float(_size - 1)) / float(_size))
	var board_px := _cell * float(_size) + GAP * float(_size - 1)
	# 棋盘只占实际需要的尺寸（而非固定最大值），这样 HUD 和小屏幕都不会被挤出去。
	_board_area.custom_minimum_size = Vector2(board_px, board_px)
	_origin = Vector2.ZERO

	for v in range(1, _size * _size):
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.size = Vector2(_cell, _cell)
		b.custom_minimum_size = Vector2(_cell, _cell)
		b.clip_contents = true
		_style_tile(b, v)
		b.pressed.connect(_on_tile_pressed.bind(v))
		_board_area.add_child(b)
		_tile_nodes[v] = b

	_sync_positions(false)

func _style_tile(btn: Button, value: int) -> void:
	var base := ThemeManager.tile_color(value)
	var shadow := ThemeManager.color("shadow")
	var tc := ThemeManager.color("text")

	var make := func(bg: Color, sh: int, off: float) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.corner_radius_top_left = 18
		s.corner_radius_top_right = 18
		s.corner_radius_bottom_left = 18
		s.corner_radius_bottom_right = 18
		s.shadow_size = sh
		s.shadow_offset = Vector2(0, off)
		s.shadow_color = shadow
		return s

	btn.add_theme_stylebox_override("normal", make.call(base, 6, 3.0))
	btn.add_theme_stylebox_override("hover", make.call(base.lightened(0.08), 9, 4.5))
	btn.add_theme_stylebox_override("pressed", make.call(base.darkened(0.06), 2, 1.0))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var f := int(clampf(_cell * 0.42, 18.0, 52.0))
	btn.add_theme_font_size_override("font_size", f)
	for st in ["font_color", "font_hover_color", "font_pressed_color"]:
		btn.add_theme_color_override(st, tc)

	btn.text = _tile_text(value) if (_mode != Constants.Mode.MEMORY or _memory_reveal) else ""

func _tile_text(v: int) -> String:
	match SettingsManager.get_int("tile_style"):
		1:
			return _to_chinese(v)
		2:
			return "●" if v % 2 == 0 else "○"
		_:
			return str(v)

func _to_chinese(v: int) -> String:
	const CN := ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
	if v <= 10:
		return CN[v]
	if v < 20:
		return "十" + CN[v - 10]
	if v < 100:
		var tens := int(v / 10)
		var ones := v % 10
		return CN[tens] + "十" + ("" if ones == 0 else CN[ones])
	return str(v)

func _cell_pos(index: int) -> Vector2:
	var r := int(index / _size)
	var c := index % _size
	return _origin + Vector2(c * (_cell + GAP), r * (_cell + GAP))

func _sync_positions(animate: bool) -> void:
	if _move_tween != null and _move_tween.is_valid():
		_move_tween.kill()
	_move_tween = null

	var dur := ThemeManager.motion_time(0.12)
	var use_anim := animate and dur > 0.0
	for i in range(_board.total()):
		var v: int = _board.tiles[i]
		if v == 0:
			continue
		var node: Button = _tile_nodes.get(v)
		if node == null:
			continue
		var target := _cell_pos(i)
		if not use_anim:
			node.position = target
		elif not node.position.is_equal_approx(target):
			# 每次移动只有 1 个方块位置改变：只为真正需要移动的方块建补间，
			# 并复用同一个 Tween，避免每步为整盘 N 个方块各创建一条补间。
			if _move_tween == null:
				_move_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			_move_tween.parallel().tween_property(node, "position", target, dur)

func _on_tile_pressed(value: int) -> void:
	if not _is_running or _is_finished:
		return
	if _mode == Constants.Mode.MEMORY and _memory_reveal:
		return

	var idx := _board.find_value(value)
	if idx < 0:
		return
	if not _board.can_move(idx):
		AudioManager.play_sfx("invalid")
		_shake(_tile_nodes[value])
		EventBus.move_rejected.emit()
		return
	_apply_move(idx)

func _apply_move(idx: int) -> void:
	var from := _board.empty_index
	var value: int = _board.tiles[idx]
	_board.move(idx)
	_steps += 1

	_history.append(from)
	if _history.size() > HISTORY_LIMIT:
		_history.pop_front()

	AudioManager.play_sfx("move", 1.0 + randf() * 0.06)
	_sync_positions(true)
	_update_hud()

	EventBus.tile_moved.emit(from, idx, value)
	EventBus.move_committed.emit(_steps)

	_tutorial_after_move()
	_check_end()
	if not _is_finished:
		_check_progress_milestone()

func _check_end() -> void:
	if _board.is_solved():
		_finish(true, Constants.EndReason.SOLVED)
		return
	if _mode == Constants.Mode.MOVE_LIMIT and _steps >= GameSession.limit_moves:
		_finish(false, Constants.EndReason.MOVE_OUT)

func _process(delta: float) -> void:
	if not _is_running or _is_finished:
		return

	_elapsed += delta
	_hud_accum += delta
	if _hud_accum >= 0.1:
		_hud_accum = 0.0
		_update_hud()

	if _mode == Constants.Mode.MEMORY and _memory_reveal:
		_memory_timer -= delta
		if _memory_timer <= 0.0:
			_memory_reveal = false
			_hide_numbers()
			_toast("🔒 数字藏起来了，凭记忆把它们拼好吧！")

	if _mode == Constants.Mode.TIME_ATTACK and _elapsed >= GameSession.limit_time:
		_finish(false, Constants.EndReason.TIME_OUT)

func _hide_numbers() -> void:
	for v in _tile_nodes:
		var b: Button = _tile_nodes[v]
		b.text = ""

func _show_numbers() -> void:
	for v in _tile_nodes:
		var b: Button = _tile_nodes[v]
		b.text = _tile_text(v)

func _update_hud() -> void:
	_steps_label.text = "步数 %d" % _steps
	_timer_label.text = _fmt(_elapsed)
	_undo_btn.disabled = _history.is_empty() or _is_finished
	_update_progress()

	if _mode == Constants.Mode.TIME_ATTACK:
		var remain := maxf(0.0, GameSession.limit_time - _elapsed)
		_limit_label.text = "剩余时间 %s" % _fmt(remain)
		_timer_label.text = "%s / %s" % [_fmt(_elapsed), _fmt(GameSession.limit_time)]
	elif _mode == Constants.Mode.MOVE_LIMIT:
		var remain := maxi(0, GameSession.limit_moves - _steps)
		_limit_label.text = "剩余步数 %d" % remain
	elif _mode == Constants.Mode.ENDLESS:
		_limit_label.text = "当前连胜 %d" % _streak
	elif _mode == Constants.Mode.DAILY:
		_limit_label.text = "📅 每日一题 · %s" % _daily_key
	else:
		_limit_label.text = ""

	EventBus.timer_updated.emit(_elapsed, maxf(0.0, GameSession.limit_time - _elapsed))

func _fmt(t: float) -> String:
	return Constants.fmt_time(t)

## 已归位的方块数量占总数的百分比，直观、低龄也能看懂。
func _progress_percent() -> int:
	if _board == null:
		return 0
	var total := _board.total() - 1
	if total <= 0:
		return 0
	var correct := 0
	for i in range(total):
		if _board.tiles[i] == i + 1:
			correct += 1
	return int(round(100.0 * float(correct) / float(total)))

func _update_progress() -> void:
	if _progress_bar == null or _progress_label == null:
		return
	var pct := _progress_percent()
	_progress_bar.value = pct
	_progress_label.text = "完成度 %d%%" % pct

## 每跨过 25% 就给一句鼓励，正向反馈比催促更管用。
func _check_progress_milestone() -> void:
	if _is_finished or (_mode == Constants.Mode.MEMORY and _memory_reveal):
		return
	var pct := _progress_percent()
	for m in [75, 50, 25]:
		if pct >= m and _progress_milestone < m:
			_progress_milestone = m
			match m:
				25: _toast("🌟 四分之一啦，找到感觉了！")
				50: _toast("💪 完成一半，真棒！")
				75: _toast("🚀 就快拼好了，冲呀！")
			return

func _on_undo() -> void:
	if _history.is_empty() or _is_finished:
		return
	# 上一步移动前空位在 from，把 now 在 from 的方块移回空位即完成撤销。
	var from: int = _history.pop_back()
	_board.move(from)
	_steps -= 1
	_undo_used = true
	AudioManager.play_sfx("undo")
	_sync_positions(true)
	_update_hud()
	EventBus.move_undone.emit(_steps)

func _on_hint() -> void:
	if _is_finished:
		return
	var idx := -1
	if _size <= 3:
		# 3×3 可在预算内求出最优解，提示即最优走法
		var r := PuzzleSolver.solve(_board, 60, 40_000, 150)
		if bool(r["ok"]) and not (r["moves"] as Array).is_empty():
			idx = int(r["moves"][0])
	if idx < 0:
		# 大棋盘退化为一步启发式建议，O(n²) 立即返回，不会卡顿
		idx = PuzzleSolver.suggest(_board)
		if idx >= 0 and _size > 3:
			_toast("💡 试试移动这块（参考走法）")
	if idx < 0:
		_toast("🤔 暂时没有提示")
		return
	var v: int = _board.tiles[idx]
	var node: Button = _tile_nodes.get(v)
	if node:
		_flash(node)
	AudioManager.play_sfx("hint")
	EventBus.hint_shown.emit(idx)

func _on_restart() -> void:
	if SettingsManager.get_bool("confirm_restart"):
		_confirm_restart()
	else:
		_do_restart()

func _confirm_restart() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "确定要重新开始本局吗？当前进度将丢失。"
	dlg.title = "重新开始"
	dlg.ok_button_text = "确定"
	dlg.cancel_button_text = "取消"
	add_child(dlg)
	dlg.confirmed.connect(func():
		dlg.queue_free()
		_do_restart()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	dlg.close_requested.connect(func(): dlg.queue_free())
	dlg.popup_centered()

func _do_restart() -> void:
	GameSession.new_board()
	_board = GameSession.board
	_steps = 0
	_elapsed = 0.0
	_hud_accum = 0.0
	_is_finished = false
	_is_running = true
	_history.clear()
	_undo_used = false
	_progress_milestone = 0
	if _tutorial_overlay != null:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null
	if _mode == Constants.Mode.MEMORY:
		_memory_reveal = true
		_memory_timer = Constants.MEMORY_SHOW_SECONDS
	else:
		_memory_reveal = false
	_create_tiles()
	_update_hud()

func _on_back() -> void:
	GameSession.steps = _steps
	GameSession.elapsed = _elapsed
	GameSession.used_undo = _undo_used
	GameSession.persist()
	TransitionManager.change_scene(Constants.SCENE_MAIN_MENU)

func _finish(won: bool, reason: int) -> void:
	if _is_finished:
		return
	_is_finished = true
	_is_running = false

	if won and _mode == Constants.Mode.MEMORY:
		_show_numbers()

	var optimal := -1
	var stars := 0
	if won:
		if _size <= 4:
			optimal = GameSession.compute_optimal()
		stars = _evaluate_stars(optimal)

	var res := {
		"mode": _mode,
		"size": _size,
		"won": won,
		"reason": reason,
		"steps": _steps,
		"time": _elapsed,
		"stars": stars,
		"optimal": optimal,
		"used_undo": _undo_used,
		"streak": _streak,
	}

	GameSession.steps = _steps
	GameSession.elapsed = _elapsed
	GameSession.used_undo = _undo_used
	GameSession.last_result = res

	var changes := StatsManager.submit_result(res)
	res["changes"] = changes
	GameSession.stats_changes = changes
	AchievementManager.evaluate(res)

	EventBus.game_finished.emit(res)

	if won:
		AudioManager.play_sfx("win")
		await get_tree().create_timer(0.30).timeout
		TransitionManager.change_scene(Constants.SCENE_WIN)
	else:
		AudioManager.play_sfx("lose")
		_show_fail_overlay(reason)

func _evaluate_stars(optimal: int) -> int:
	if optimal <= 0:
		var ratio := float(_steps) / float(_size * _size * 7)
		if ratio <= 0.45:
			return 3
		if ratio <= 0.75:
			return 2
		return 1
	var r := float(_steps) / float(optimal)
	if r <= Constants.STAR3_RATIO:
		return 3
	if r <= Constants.STAR2_RATIO:
		return 2
	return 1

func _reason_text(reason: int) -> String:
	match reason:
		Constants.EndReason.TIME_OUT: return "⏰ 时间到了，再快一点点"
		Constants.EndReason.MOVE_OUT: return "👣 步数用完了，试试更少的步数"
		_: return "挑战结束"

func _show_fail_overlay(reason: int) -> void:
	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0.55)
	add_child(ov)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		UIFactory.panel_style(ThemeManager.color("card"), 26, 16, ThemeManager.color("shadow")))
	center.add_child(card)

	var margin := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 28)
	card.add_child(margin)

	var vb := UIFactory.make_vbox(16)
	margin.add_child(vb)

	var title := UIFactory.make_label("就差一点啦！", ThemeManager.scaled(36), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sub := UIFactory.make_label(_reason_text(reason), ThemeManager.scaled(20), ThemeManager.color("text_dim"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var cheer := UIFactory.make_label("再试一次，你一定可以的！", ThemeManager.scaled(20), ThemeManager.color("accent"))
	cheer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(cheer)

	var stat := UIFactory.make_label("步数 %d · 用时 %s" % [_steps, _fmt(_elapsed)],
		ThemeManager.scaled(18), ThemeManager.color("text_dim"))
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stat)

	var retry := UIFactory.make_button("重新开始", ThemeManager.color("accent"),
		ThemeManager.scaled(20), Vector2(260, 56), ThemeManager.color("text"))
	retry.pressed.connect(func():
		ov.queue_free()
		_do_restart()
	)
	vb.add_child(retry)

	var back := UIFactory.make_button("返回主菜单", ThemeManager.color("card_alt"),
		ThemeManager.scaled(20), Vector2(260, 56), ThemeManager.color("text"))
	back.pressed.connect(func(): TransitionManager.change_scene(Constants.SCENE_MAIN_MENU))
	vb.add_child(back)

# ── 新手引导 ─────────────────

## 首次进入自动弹出；孩子也可随时点“玩法”重看。
func _show_tutorial(first_time: bool) -> void:
	if _tutorial_overlay != null:
		return
	_tutorial_first_time = first_time
	_is_running = false

	var ov := ColorRect.new()
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.color = Color(0, 0, 0, 0.55)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	_tutorial_overlay = ov

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		UIFactory.panel_style(ThemeManager.color("card"), 28, 16, ThemeManager.color("shadow")))
	center.add_child(card)

	var margin := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 30)
	card.add_child(margin)

	var vb := UIFactory.make_vbox(14)
	margin.add_child(vb)

	var title := UIFactory.make_label("🧩 怎么玩？", ThemeManager.scaled(38), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	vb.add_child(_tutorial_line("🎯", "把数字按 1 → %d 的顺序排好" % (_size * _size - 1)))
	vb.add_child(_tutorial_line("👆", "点一下空格旁边的方块，它就会滑过去"))
	vb.add_child(_tutorial_line("⬜", "最后的空位留在右下角就赢啦"))
	vb.add_child(_tutorial_line("↩️", "走错了就点“撤销”，不用害怕试错"))
	if SettingsManager.get_bool("keyboard_control"):
		vb.add_child(_tutorial_line("⌨️", "也可以用方向键，让方块朝箭头方向滑动"))
	vb.add_child(_tutorial_line("💡", "卡住了就点“提示”，会告诉你下一步"))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	vb.add_child(gap)

	var ok := UIFactory.make_button("我明白啦！", ThemeManager.color("accent"),
		ThemeManager.scaled(22), Vector2(280, 60), ThemeManager.color("text"))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_close_tutorial)
	vb.add_child(ok)

func _tutorial_line(icon: String, text: String) -> Label:
	var l := UIFactory.make_label("%s  %s" % [icon, text],
		ThemeManager.scaled(19), ThemeManager.color("text"))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _close_tutorial() -> void:
	if _tutorial_overlay == null:
		return
	_tutorial_overlay.queue_free()
	_tutorial_overlay = null
	if not _is_finished:
		_is_running = true
	_update_hud()

	if _tutorial_first_time:
		SettingsManager.set_value("tutorial_seen", true)
		_tutorial_first_time = false
		_tutorial_waiting_first_move = true
		_highlight_movable_tile()
		_toast("试着点一下闪烁的方块吧！")

func _highlight_movable_tile() -> void:
	for idx in _board.neighbors(_board.empty_index):
		var v: int = _board.tiles[idx]
		if v != 0 and _tile_nodes.has(v):
			_flash(_tile_nodes[v])
			return

func _tutorial_after_move() -> void:
	if _tutorial_waiting_first_move:
		_tutorial_waiting_first_move = false
		_toast("就是这样！👍 继续加油！")

# ── 键盘操作（方便用电脑的孩子） ──────────

func _unhandled_input(event: InputEvent) -> void:
	if not SettingsManager.get_bool("keyboard_control"):
		return
	if not _is_running or _is_finished or _tutorial_overlay != null:
		return
	if _mode == Constants.Mode.MEMORY and _memory_reveal:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	var empty := _board.empty_index
	@warning_ignore("integer_division")
	var row := int(empty / _size)
	var col := empty % _size
	var idx := -1
	# 按方向键 = 让方块朝该方向滑动，因此取空位的反方向邻居。
	match event.keycode:
		KEY_LEFT:
			if col < _size - 1: idx = empty + 1
		KEY_RIGHT:
			if col > 0: idx = empty - 1
		KEY_UP:
			if row < _size - 1: idx = empty + _size
		KEY_DOWN:
			if row > 0: idx = empty - _size
		_:
			return
	if idx >= 0 and _board.can_move(idx):
		_apply_move(idx)
		get_viewport().set_input_as_handled()

func _shake(node: Control) -> void:
	if node == null or SettingsManager.get_bool("reduce_motion"):
		return
	var base := node.position
	var tw := create_tween()
	for i in range(4):
		var off := 6.0 if i % 2 == 0 else -6.0
		tw.tween_property(node, "position", base + Vector2(off, 0), 0.035)
	tw.tween_property(node, "position", base, 0.035)

func _flash(node: Control) -> void:
	if node == null:
		return
	if SettingsManager.get_bool("reduce_motion"):
		node.modulate = Color(1.5, 1.5, 1.5, 1.0)
		create_tween().tween_property(node, "modulate", Color.WHITE, 0.25)
		return
	var tw := create_tween().set_loops(3)
	tw.tween_property(node, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.14)
	tw.tween_property(node, "modulate", Color.WHITE, 0.14)

func _toast(text: String) -> void:
	EventBus.request_toast.emit(text, 0)

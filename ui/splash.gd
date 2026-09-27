extends Control

func _ready() -> void:
	_build()
	_boot()

func _build() -> void:
	add_child(UIFactory.make_backdrop(ThemeManager.color("bg")))

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vb := UIFactory.make_vbox(14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vb)

	var title := UIFactory.make_label("数字华容道", ThemeManager.scaled(60), ThemeManager.color("text"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var sub := UIFactory.make_label("NUMBER KLOTSKI", ThemeManager.scaled(18), ThemeManager.color("text_dim"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vb.add_child(spacer)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(280, 8)
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = 0.0
	var bg_sb := StyleBoxFlat.new()
	bg_sb.bg_color = ThemeManager.color("card_alt")
	bg_sb.corner_radius_top_left = 6
	bg_sb.corner_radius_top_right = 6
	bg_sb.corner_radius_bottom_left = 6
	bg_sb.corner_radius_bottom_right = 6
	var fg_sb := StyleBoxFlat.new()
	fg_sb.bg_color = ThemeManager.color("accent")
	fg_sb.corner_radius_top_left = 6
	fg_sb.corner_radius_top_right = 6
	fg_sb.corner_radius_bottom_left = 6
	fg_sb.corner_radius_bottom_right = 6
	bar.add_theme_stylebox_override("background", bg_sb)
	bar.add_theme_stylebox_override("fill", fg_sb)
	vb.add_child(bar)

	title.modulate.a = 0.0
	sub.modulate.a = 0.0
	bar.modulate.a = 0.0

	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(title, "modulate:a", 1.0, 0.35)
	tw.parallel().tween_property(sub, "modulate:a", 1.0, 0.35)
	tw.tween_property(bar, "modulate:a", 1.0, 0.2)
	tw.tween_property(bar, "value", 100.0, 0.55).set_trans(Tween.TRANS_CUBIC)

func _boot() -> void:
	await get_tree().process_frame
	SaveManager.save_now()
	await get_tree().create_timer(0.7).timeout
	TransitionManager.change_scene(Constants.SCENE_MAIN_MENU)
extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

var _busy: bool = false

func _ready() -> void:
	# 跟随当前主题背景色，避免深色/高对比主题下转场闪出浅色。
	rect.color = ThemeManager.color("bg")
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0

func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP

	# 转场前持久化
	GameSession.persist()
	SaveManager.save_now()

	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rect, "modulate:a", 1.0, 0.22)
	await tween.finished

	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[TransitionManager] 场景加载失败: " + path)
		rect.modulate.a = 0.0
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_busy = false
		return

	await get_tree().process_frame
	await get_tree().create_timer(0.06).timeout

	var out := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	out.tween_property(rect, "modulate:a", 0.0, 0.22)
	await out.finished

	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func fade_in_only() -> void:
	rect.modulate.a = 1.0
	var out := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	out.tween_property(rect, "modulate:a", 0.0, 0.30)

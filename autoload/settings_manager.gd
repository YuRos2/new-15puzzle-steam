extends Node
## 读写 SaveManager 的 settings 段，变更时广播 EventBus.settings_changed。

const DEFAULTS: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.55,
	"sfx_volume": 0.85,
	"mute": false,
	"theme": 0,          # 0 浅色 / 1 深色 / 2 高对比
	"tile_style": 0,     # 0 数字 / 1 汉字 / 2 符号
	"font_scale": 1.0,
	"reduce_motion": false,
	"show_timer": true,
	"confirm_restart": true,
	"tutorial_seen": false,      # 是否看过新手引导
	"keyboard_control": true,    # 方向键也能滑动方块
}

var _d: Dictionary = {}

func _ready() -> void:
	_d = SaveManager.section("settings")
	var changed := false
	for k in DEFAULTS:
		if not _d.has(k):
			_d[k] = DEFAULTS[k]
			changed = true
	# 只有真的补了默认值才写盘，避免每次启动都无谓地重写存档。
	if changed:
		SaveManager.mark_dirty()

func get_value(key: String) -> Variant:
	if _d.has(key):
		return _d[key]
	return DEFAULTS.get(key)

func get_float(key: String) -> float:
	return float(get_value(key))

func get_bool(key: String) -> bool:
	return bool(get_value(key))

func get_int(key: String) -> int:
	return int(get_value(key))

func set_value(key: String, value: Variant) -> void:
	if _d.has(key) and _d[key] == value:
		return
	_d[key] = value
	SaveManager.mark_dirty()
	EventBus.settings_changed.emit(key, value)

func reset_all() -> void:
	for k in DEFAULTS:
		_d[k] = DEFAULTS[k]
		EventBus.settings_changed.emit(k, DEFAULTS[k])
	SaveManager.mark_dirty()
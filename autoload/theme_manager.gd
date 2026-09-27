extends Node
## 所有界面通过 ThemeManager 取色，实现一键换肤。

enum ThemeId { LIGHT, DARK, CONTRAST }

const PALETTES: Dictionary = {
	ThemeId.LIGHT: {
		"bg":        Color("#FDF6F0"),
		"card":      Color("#FFFFFF"),
		"card_alt":  Color("#F6EFE9"),
		"text":      Color("#3D3D3D"),
		"text_dim":  Color("#9A9089"),
		"shadow":    Color(0.55, 0.45, 0.40, 0.16),
		"empty":     Color("#EDE4DC"),
		"accent":    Color("#FFB7B2"),
		"accent2":   Color("#B5EAD7"),
		"accent3":   Color("#C7CEEA"),
		"accent4":   Color("#E2F0CB"),
		"accent5":   Color("#FFDAC1"),
	},
	ThemeId.DARK: {
		"bg":        Color("#221F26"),
		"card":      Color("#2E2A33"),
		"card_alt":  Color("#3A3540"),
		"text":      Color("#F2ECE6"),
		"text_dim":  Color("#A79FA8"),
		"shadow":    Color(0, 0, 0, 0.45),
		"empty":     Color("#3A3540"),
		"accent":    Color("#FFB7B2"),
		"accent2":   Color("#7FBFAA"),
		"accent3":   Color("#8E97C4"),
		"accent4":   Color("#A8BE8F"),
		"accent5":   Color("#D9B58C"),
	},
	ThemeId.CONTRAST: {
		"bg":        Color("#000000"),
		"card":      Color("#101010"),
		"card_alt":  Color("#1C1C1C"),
		"text":      Color("#FFFFFF"),
		"text_dim":  Color("#C8C8C8"),
		"shadow":    Color(0, 0, 0, 0.85),
		"empty":     Color("#2A2A2A"),
		"accent":    Color("#FFD400"),
		"accent2":   Color("#00E5FF"),
		"accent3":   Color("#FF6EC7"),
		"accent4":   Color("#7CFF6B"),
		"accent5":   Color("#FF9E3D"),
	},
}

const TILE_COLORS: Dictionary = {
	ThemeId.LIGHT: [
		Color("#FFB7B2"), Color("#B5EAD7"), Color("#C7CEEA"),
		Color("#E2F0CB"), Color("#FFDAC1"),
	],
	ThemeId.DARK: [
		Color("#D98C86"), Color("#7FBFAA"), Color("#8E97C4"),
		Color("#A8BE8F"), Color("#D9B58C"),
	],
	ThemeId.CONTRAST: [
		Color("#FFD400"), Color("#00E5FF"), Color("#FF6EC7"),
		Color("#7CFF6B"), Color("#FF9E3D"),
	],
}

var _id: int = ThemeId.LIGHT

func _ready() -> void:
	_id = clampi(SettingsManager.get_int("theme"), 0, 2)
	EventBus.settings_changed.connect(_on_setting_changed)

func _on_setting_changed(key: String, value: Variant) -> void:
	if key == "theme":
		set_theme(int(value))

func set_theme(id: int) -> void:
	id = clampi(id, 0, 2)
	if id == _id:
		return
	_id = id
	EventBus.theme_changed.emit(id)

func current_id() -> int:
	return _id

func color(key: String) -> Color:
	var p: Dictionary = PALETTES[_id]
	return p.get(key, Color.MAGENTA)

func tile_color(value: int) -> Color:
	var arr: Array = TILE_COLORS[_id]
	return arr[(value - 1) % arr.size()]

func font_scale() -> float:
	return SettingsManager.get_float("font_scale")

func scaled(base: int) -> int:
	return int(round(base * font_scale()))

## 尊重「减少动画」选项的时间缩放
func motion_time(base: float) -> float:
	if SettingsManager.get_bool("reduce_motion"):
		return 0.0
	return base
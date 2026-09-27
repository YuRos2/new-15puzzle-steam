extends Node
## 自动加载名：Constants

enum Mode { CLASSIC, TIME_ATTACK, MOVE_LIMIT, MEMORY, DAILY, ENDLESS }
enum EndReason { SOLVED, TIME_OUT, MOVE_OUT, ABORTED, QUIT }

const BOARD_SIZES: Array[int] = [3, 4, 5, 6]

## 面向中小学生的难度叫法，比单纯的 3×3 / 4×4 更好懂。
const SIZE_LABEL: Dictionary = {
	3: "入门",
	4: "经典",
	5: "进阶",
	6: "大师",
}

## 首次进入推荐从 3×3 开始，降低挫败感。
const RECOMMENDED_SIZE: int = 3

const MODE_INFO: Dictionary = {
	Mode.CLASSIC:     {"name": "🧸 自由拼图", "desc": "慢慢玩，没有时间限制", "color": "#FFB7B2"},
	Mode.TIME_ATTACK: {"name": "⏰ 限时闯关", "desc": "在时间用完前拼好棋盘", "color": "#FFDAC1"},
	Mode.MOVE_LIMIT:  {"name": "👣 限步闯关", "desc": "用尽量少的步数拼好",   "color": "#B5EAD7"},
	Mode.MEMORY:      {"name": "🧠 记忆挑战", "desc": "先记住数字，再把它拼好", "color": "#C7CEEA"},
	Mode.DAILY:       {"name": "📅 每日一题", "desc": "每天都有新题目",     "color": "#E2F0CB"},
	Mode.ENDLESS:     {"name": "🚀 闯关模式", "desc": "一关接一关，越来越难", "color": "#F8C8DC"},
}

const TIME_LIMIT: Dictionary    = {3: 180.0, 4: 420.0, 5: 720.0, 6: 1080.0}
const MOVE_LIMIT: Dictionary    = {3: 80,    4: 200,   5: 400,   6: 700}
const MEMORY_SHOW_SECONDS: float = 3.0

# 星级阈值：实际步数 / 最优步数
const STAR3_RATIO: float = 1.30
const STAR2_RATIO: float = 1.75

const SCENE_SPLASH       := "res://scenes/splash.tscn"
const SCENE_MAIN_MENU    := "res://scenes/main_menu.tscn"
const SCENE_MODE_SELECT  := "res://scenes/mode_select.tscn"
const SCENE_GAME         := "res://scenes/game.tscn"
const SCENE_WIN          := "res://scenes/win_screen.tscn"
const SCENE_SETTINGS     := "res://scenes/settings.tscn"
const SCENE_ACHIEVEMENTS := "res://scenes/achievements.tscn"
const SCENE_STATS        := "res://scenes/stats.tscn"

func mode_name(m: int) -> String:
	return MODE_INFO.get(m, {}).get("name", "未知模式")

func mode_desc(m: int) -> String:
	return MODE_INFO.get(m, {}).get("desc", "")

## 统一的 mm:ss 时间格式化，避免各界面各写一份。
func fmt_time(t: float) -> String:
	var m := int(t / 60.0)
	var s := int(t) % 60
	return "%02d:%02d" % [m, s]

func size_label(s: int) -> String:
	return SIZE_LABEL.get(s, "挑战")

func star_text(stars: int) -> String:
	match stars:
		3: return "★★★"
		2: return "★★☆"
		1: return "★☆☆"
		_: return "☆☆☆"
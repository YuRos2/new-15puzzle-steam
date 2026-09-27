extends Node

const ACHIEVEMENTS: Array = [
	{"id": "first_win",     "name": "第一次通关", "desc": "完成一局拼图",                     "icon": "🌱"},
	{"id": "speed_3x3",     "name": "闪电快手",   "desc": "30 秒内完成 3×3 拼图",             "icon": "⚡"},
	{"id": "low_steps_3x3", "name": "省步小能手", "desc": "用很少的步数完成 3×3",            "icon": "🎯"},
	{"id": "big_board",     "name": "拼图大王",   "desc": "完成一局 6×6 大拼图",              "icon": "🧩"},
	{"id": "daily_7",       "name": "坚持小达人", "desc": "累计完成 7 次每日一题",           "icon": "📅"},
	{"id": "streak_10",     "name": "十连胜",     "desc": "闯关模式达成 10 连胜",             "icon": "🔥"},
	{"id": "no_undo",       "name": "一往无前",   "desc": "不用撤销完成一局 4×4",             "icon": "🚀"},
	{"id": "memory_master", "name": "记忆小天才", "desc": "完成一局记忆挑战",                "icon": "🧠"},
	{"id": "games_50",      "name": "拼图小达人", "desc": "累计完成 50 局游戏",               "icon": "🏅"},
	{"id": "perfect_3star", "name": "满分三星",   "desc": "在一局中获得三星评价",             "icon": "⭐"},
]

var _d: Dictionary = {}

func _ready() -> void:
	_d = SaveManager.section("achievements")

func is_unlocked(id: String) -> bool:
	return bool(_d.get(id, false))

func unlock(id: String) -> void:
	if is_unlocked(id):
		return
	_d[id] = true
	SaveManager.mark_dirty()
	EventBus.achievement_unlocked.emit(id)
	AudioManager.play_sfx("achievement")
	EventBus.request_toast.emit("成就解锁：" + info(id).get("name", id), 1)

func unlocked_count() -> int:
	var n := 0
	for a in ACHIEVEMENTS:
		if is_unlocked(a["id"]):
			n += 1
	return n

func total_count() -> int:
	return ACHIEVEMENTS.size()

func info(id: String) -> Dictionary:
	for a in ACHIEVEMENTS:
		if a["id"] == id:
			return a
	return {}

## ctx: mode, size, won, steps, time, stars, optimal, used_undo
func evaluate(ctx: Dictionary) -> void:
	_check_volume_achievements()
	if not bool(ctx.get("won", false)):
		return

	var mode: int     = int(ctx.get("mode", 0))
	var size: int     = int(ctx.get("size", 4))
	var time_s: float = float(ctx.get("time", 0.0))
	var steps: int    = int(ctx.get("steps", 0))
	var stars: int    = int(ctx.get("stars", 0))
	var optimal: int  = int(ctx.get("optimal", -1))
	var used_undo: bool = bool(ctx.get("used_undo", false))

	unlock("first_win")
	if size == 3 and time_s <= 30.0:
		unlock("speed_3x3")
	if size == 3 and optimal > 0 and steps <= int(ceil(float(optimal) * 1.2)):
		unlock("low_steps_3x3")
	if size == 6:
		unlock("big_board")
	if size == 4 and not used_undo:
		unlock("no_undo")
	if mode == Constants.Mode.MEMORY:
		unlock("memory_master")
	if stars >= 3:
		unlock("perfect_3star")
	if int(StatsManager.get_stat("best_streak")) >= 10:
		unlock("streak_10")

func _check_volume_achievements() -> void:
	if int(StatsManager.get_stat("daily_completed")) >= 7:
		unlock("daily_7")
	if int(StatsManager.get_stat("total_games")) >= 50:
		unlock("games_50")
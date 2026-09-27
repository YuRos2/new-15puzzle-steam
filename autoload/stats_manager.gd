extends Node

const RECENT_LIMIT: int = 30

var _d: Dictionary = {}

func _ready() -> void:
	_d = SaveManager.section("stats")
	_ensure_defaults()

func _ensure_defaults() -> void:
	var defs := {
		"total_games": 0,
		"wins": 0,
		"losses": 0,
		"total_steps": 0,
		"total_time": 0.0,
		"best_streak": 0,
		"current_streak": 0,
		"daily_completed": 0,
		"daily_dates": [],
		"recent": [],
		"records": {},
	}
	var changed := false
	for k in defs:
		if not _d.has(k):
			_d[k] = defs[k]
			changed = true
	if changed:
		SaveManager.mark_dirty()

func get_stat(key: String) -> Variant:
	return _d.get(key, 0)

func record_key(mode: int, size: int) -> String:
	return "%d_%d" % [mode, size]

func _new_record() -> Dictionary:
	return {
		"best_steps": -1, "best_time": -1.0,
		"best_star": 0, "games": 0, "wins": 0, "stars": 0,
	}

## 只读查询：记录不存在时返回默认值，不会写入存档。
func get_record(mode: int, size: int) -> Dictionary:
	var recs: Dictionary = _d["records"]
	var key := record_key(mode, size)
	if recs.has(key):
		return recs[key]
	return _new_record()

## 提交结果时按需创建，返回的是存档内的引用（可写入）。
func _ensure_record(mode: int, size: int) -> Dictionary:
	var recs: Dictionary = _d["records"]
	var key := record_key(mode, size)
	if not recs.has(key):
		recs[key] = _new_record()
	return recs[key]

## 提交一局结果，返回变更摘要
func submit_result(res: Dictionary) -> Dictionary:
	var mode: int    = int(res.get("mode", 0))
	var size: int    = int(res.get("size", 4))
	var won: bool    = bool(res.get("won", false))
	var steps: int   = int(res.get("steps", 0))
	var time_s: float= float(res.get("time", 0.0))
	var stars: int   = int(res.get("stars", 0))

	_d["total_games"] = int(_d["total_games"]) + 1

	var rec := _ensure_record(mode, size)
	rec["games"] = int(rec["games"]) + 1

	var changes := {
		"new_best_steps": false,
		"new_best_time": false,
		"prev_best_steps": int(rec["best_steps"]),
		"prev_best_time": float(rec["best_time"]),
	}

	if won:
		_d["wins"] = int(_d["wins"]) + 1
		_d["total_steps"] = int(_d["total_steps"]) + steps
		_d["total_time"] = float(_d["total_time"]) + time_s

		rec["wins"] = int(rec["wins"]) + 1

		if int(rec["best_steps"]) < 0 or steps < int(rec["best_steps"]):
			rec["best_steps"] = steps
			changes["new_best_steps"] = true
		if float(rec["best_time"]) < 0.0 or time_s < float(rec["best_time"]):
			rec["best_time"] = time_s
			changes["new_best_time"] = true
		if stars > int(rec["best_star"]):
			rec["best_star"] = stars
		rec["stars"] = int(rec["stars"]) + stars

		_d["current_streak"] = int(_d["current_streak"]) + 1
		if int(_d["current_streak"]) > int(_d["best_streak"]):
			_d["best_streak"] = int(_d["current_streak"])
	else:
		_d["losses"] = int(_d["losses"]) + 1
		_d["current_streak"] = 0

	if mode == Constants.Mode.DAILY and won:
		var key := PuzzleGenerator.today_key()
		var dates: Array = _d["daily_dates"]
		if not dates.has(key):
			dates.append(key)
			_d["daily_completed"] = int(_d["daily_completed"]) + 1

	var recent: Array = _d["recent"]
	recent.push_front({
		"mode": mode, "size": size, "won": won,
		"steps": steps, "time": time_s, "stars": stars,
		"ts": int(Time.get_unix_time_from_system()),
	})
	while recent.size() > RECENT_LIMIT:
		recent.pop_back()

	SaveManager.mark_dirty()
	EventBus.stats_changed.emit()
	return changes

func average_steps() -> float:
	var w := int(_d.get("wins", 0))
	if w <= 0:
		return 0.0
	return float(_d.get("total_steps", 0)) / float(w)

func average_time() -> float:
	var w := int(_d.get("wins", 0))
	if w <= 0:
		return 0.0
	return float(_d.get("total_time", 0.0)) / float(w)

func win_rate() -> float:
	var t := int(_d.get("total_games", 0))
	if t <= 0:
		return 0.0
	return float(_d.get("wins", 0)) / float(t)
extends Node
## 把"一局游戏"的参数与进度从场景中抽离，供游戏场景、结算场景与存档共享。

var mode: int = Constants.Mode.CLASSIC
var size: int = 4
var board: PuzzleBoard = null
var steps: int = 0
var elapsed: float = 0.0
var used_undo: bool = false
var undo_count: int = 0
var optimal_steps: int = -1
var limit_time: float = 0.0
var limit_moves: int = 0
var streak: int = 0
var extra: Dictionary = {}
var last_result: Dictionary = {}
var stats_changes: Dictionary = {}

func configure(p_mode: int, p_size: int, options: Dictionary = {}) -> void:
	mode = p_mode
	size = p_size
	extra = options.duplicate(true)
	streak = int(extra.get("streak", 0))
	new_board()
	EventBus.game_started.emit(mode, size)

func new_board() -> PuzzleBoard:
	var seed_value := -1
	if mode == Constants.Mode.DAILY:
		seed_value = PuzzleGenerator.daily_seed(size)
	elif extra.has("seed"):
		seed_value = int(extra["seed"])

	board = PuzzleGenerator.scramble(size, 0, seed_value)
	steps = 0
	elapsed = 0.0
	used_undo = false
	undo_count = 0
	optimal_steps = -1
	limit_time = float(Constants.TIME_LIMIT.get(size, 420.0))
	limit_moves = int(Constants.MOVE_LIMIT.get(size, 200))
	if extra.has("limit_time"):
		limit_time = float(extra["limit_time"])
	if extra.has("limit_moves"):
		limit_moves = int(extra["limit_moves"])

	# 每日挑战固定限制
	if mode == Constants.Mode.DAILY:
		limit_time = float(Constants.TIME_LIMIT.get(size, 420.0))

	EventBus.board_reset.emit(size)
	return board

## 计算最优步数。仅 3×3 可在可接受时间内求出精确最优解；
## 更大棋盘（4×4 起）的最优搜索在 GDScript 下可能耗时数十秒，直接放弃，
## 由调用方回退到比例估算星级，避免结算时卡死主线程。
func compute_optimal() -> int:
	if optimal_steps >= 0:
		return optimal_steps
	if board == null or size > 3:
		return -1
	var r := PuzzleSolver.solve(board, 80, 150_000, 1500)
	if bool(r["ok"]):
		optimal_steps = int(r["length"])
	return optimal_steps

func to_dict() -> Dictionary:
	if board == null:
		return {}
	return {
		"mode": mode, "size": size,
		"board": board.to_dict(),
		"steps": steps, "elapsed": elapsed,
		"used_undo": used_undo, "undo_count": undo_count,
		"optimal": optimal_steps,
		"streak": streak,
		"extra": extra,
		"saved_at": int(Time.get_unix_time_from_system()),
	}

func restore(d: Dictionary) -> bool:
	if d.is_empty() or not d.has("board"):
		return false
	mode = int(d.get("mode", 0))
	size = int(d.get("size", 4))
	board = PuzzleBoard.from_dict(d["board"])
	steps = int(d.get("steps", 0))
	elapsed = float(d.get("elapsed", 0.0))
	used_undo = bool(d.get("used_undo", false))
	undo_count = int(d.get("undo_count", 0))
	optimal_steps = int(d.get("optimal", -1))
	streak = int(d.get("streak", 0))
	extra = d.get("extra", {})
	limit_time = float(Constants.TIME_LIMIT.get(size, 420.0))
	limit_moves = int(Constants.MOVE_LIMIT.get(size, 200))
	if extra.has("limit_time"):
		limit_time = float(extra["limit_time"])
	if extra.has("limit_moves"):
		limit_moves = int(extra["limit_moves"])
	return true

func clear() -> void:
	board = null
	steps = 0
	elapsed = 0.0
	last_result = {}
	stats_changes = {}
	SaveManager.section("session").clear()
	SaveManager.mark_dirty()

func has_saved_session() -> bool:
	var s := SaveManager.section("session")
	return s.has("board") and not s.is_empty()

func persist() -> void:
	var s := SaveManager.section("session")
	var had_content := not s.is_empty()
	s.clear()
	var has_content := false
	if board != null and not board.is_solved():
		var d := to_dict()
		for k in d:
			s[k] = d[k]
		has_content = true
	# 仅当内容发生变化时才标记脏数据，避免每次切场景都重写同一份存档。
	if had_content or has_content:
		SaveManager.mark_dirty()

func load_saved() -> bool:
	var s := SaveManager.section("session")
	if s.is_empty():
		return false
	return restore(s)
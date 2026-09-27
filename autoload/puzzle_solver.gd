extends Node
## 使用 IDA* + 曼哈顿距离 + 行/列线性冲突启发式求解。
##
## 说明：15-puzzle 的最优解搜索在 GDScript 中代价极高（4×4 随机局面往往需要
## 数百万节点、数十秒），因此这里：
##   * 对 3×3 提供精确最优解；
##   * 通过 node_budget / time_limit_ms 强制限制最坏耗时，避免卡死主线程；
##   * 大棋盘的一步建议请使用 suggest()，它是 O(n²) 的启发式走法。

const NODE_BUDGET: int = 150_000
const MAX_DEPTH: int = 100
const TIME_CHECK_MASK: int = 255

var _n: int = 0
var _nn: int = 0
var _gr := PackedInt32Array()
var _gc := PackedInt32Array()
var _nodes_left: int = 0
var _deadline_ms: int = 0
var _ticks: int = 0

## max_depth 为最大搜索深度；node_budget 为节点上限；
## time_limit_ms > 0 时同时受墙钟时间限制。
func solve(board: PuzzleBoard, max_depth: int = MAX_DEPTH,
		node_budget: int = NODE_BUDGET, time_limit_ms: int = 0) -> Dictionary:
	var work := board.clone()
	_prepare(work.size)
	var h0 := _heuristic(work)
	if h0 == 0:
		return {"ok": true, "moves": [], "length": 0, "optimal": true, "aborted": false, "nodes": 0}

	_nodes_left = maxi(node_budget, 1)
	_deadline_ms = (Time.get_ticks_msec() + time_limit_ms) if time_limit_ms > 0 else 0
	_ticks = 0

	var path: Array[int] = []
	var bound := h0
	var guard := 0
	while guard < 256:
		guard += 1
		var t := _dfs(work, 0, bound, -1, path)
		if t == -1:
			return {"ok": true, "moves": path.duplicate(), "length": path.size(),
					"optimal": true, "aborted": false, "nodes": node_budget - _nodes_left}
		if t == -2:
			return {"ok": false, "moves": [], "length": -1, "optimal": false,
					"aborted": true, "nodes": node_budget - _nodes_left}
		if t > max_depth:
			break
		bound = t

	return {"ok": false, "moves": [], "length": -1, "optimal": false,
			"aborted": false, "nodes": node_budget - _nodes_left}

## 返回一步"还不错"的走法索引（不保证最优，但 O(n²) 立即返回）。
## 无法移动时返回 -1。用于大棋盘提示，避免最优搜索卡顿。
func suggest(board: PuzzleBoard) -> int:
	if board == null or board.is_solved():
		return -1
	_prepare(board.size)
	var e := board.empty_index
	var best_idx := -1
	var best_h := 1 << 30
	for idx in board.neighbors(e):
		board.move(idx)
		var h := _heuristic(board)
		board.move(e)
		if h < best_h:
			best_h = h
			best_idx = idx
	return best_idx

func _prepare(n: int) -> void:
	_n = n
	_nn = n * n
	_gr.resize(_nn + 1)
	_gc.resize(_nn + 1)
	for v in range(1, _nn):
		@warning_ignore("integer_division")
		var r := (v - 1) / n
		_gr[v] = r
		_gc[v] = (v - 1) % n

func _dfs(board: PuzzleBoard, g: int, bound: int, prev: int, path: Array[int]) -> int:
	_nodes_left -= 1
	if _nodes_left <= 0:
		return -2
	if _deadline_ms > 0:
		_ticks += 1
		if (_ticks & TIME_CHECK_MASK) == 0 and Time.get_ticks_msec() >= _deadline_ms:
			return -2

	var h := _heuristic(board)
	var f := g + h
	if f > bound:
		return f
	if h == 0:
		return -1

	var n := _n
	var e := board.empty_index
	@warning_ignore("integer_division")
	var row := e / n
	var col := e % n
	var best := 1 << 30

	# 上 / 下 / 左 / 右，内联展开以避免每次节点分配数组
	if row > 0:
		var idx := e - n
		if idx != prev:
			board.move(idx); path.append(idx)
			var r := _dfs(board, g + 1, bound, e, path)
			if r == -1: return -1
			if r == -2: path.pop_back(); board.move(e); return -2
			if r < best: best = r
			path.pop_back(); board.move(e)
	if row < n - 1:
		var idx := e + n
		if idx != prev:
			board.move(idx); path.append(idx)
			var r := _dfs(board, g + 1, bound, e, path)
			if r == -1: return -1
			if r == -2: path.pop_back(); board.move(e); return -2
			if r < best: best = r
			path.pop_back(); board.move(e)
	if col > 0:
		var idx := e - 1
		if idx != prev:
			board.move(idx); path.append(idx)
			var r := _dfs(board, g + 1, bound, e, path)
			if r == -1: return -1
			if r == -2: path.pop_back(); board.move(e); return -2
			if r < best: best = r
			path.pop_back(); board.move(e)
	if col < n - 1:
		var idx := e + 1
		if idx != prev:
			board.move(idx); path.append(idx)
			var r := _dfs(board, g + 1, bound, e, path)
			if r == -1: return -1
			if r == -2: path.pop_back(); board.move(e); return -2
			if r < best: best = r
			path.pop_back(); board.move(e)

	return best

func _heuristic(board: PuzzleBoard) -> int:
	var n := _n
	var t: Array[int] = board.tiles
	var gr := _gr
	var gc := _gc
	var h := 0

	for i in range(_nn):
		var v: int = t[i]
		if v == 0:
			continue
		@warning_ignore("integer_division")
		var ir := i / n
		h += absi(ir - gr[v]) + absi(i % n - gc[v])

	# 行线性冲突
	for r in range(n):
		var base := r * n
		for c1 in range(n):
			var v1: int = t[base + c1]
			if v1 == 0 or gr[v1] != r:
				continue
			for c2 in range(c1 + 1, n):
				var v2: int = t[base + c2]
				if v2 == 0 or gr[v2] != r:
					continue
				if v1 > v2:
					h += 2
	# 列线性冲突
	for c in range(n):
		for r1 in range(n):
			var v1: int = t[r1 * n + c]
			if v1 == 0 or gc[v1] != c:
				continue
			for r2 in range(r1 + 1, n):
				var v2: int = t[r2 * n + c]
				if v2 == 0 or gc[v2] != c:
					continue
				if v1 > v2:
					h += 2
	return h

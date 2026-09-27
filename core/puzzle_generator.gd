class_name PuzzleGenerator
extends RefCounted
## 从目标状态出发，反向执行随机合法移动来生成打乱棋盘。
## 这样得到的棋盘必然可解，且不会出现"已复原"或"太简单"的极端情况。

## seed_value < 0 表示使用随机种子；>= 0 表示可复现（每日挑战用）
static func scramble(board_size: int, moves: int = 0, seed_value: int = -1) -> PuzzleBoard:
	var board := PuzzleBoard.new(board_size)
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	if moves <= 0:
		moves = board_size * board_size * 14

	var prev_empty := -1
	for _i in range(moves):
		var all_n := board.neighbors(board.empty_index)
		var pool: Array[int] = []
		for n in all_n:
			if n != prev_empty:
				pool.append(n)
		if pool.is_empty():
			pool = all_n
		var pick: int = pool[rng.randi_range(0, pool.size() - 1)]
		prev_empty = board.empty_index
		board.move(pick)

	# 极小概率会恰好走回目标状态。
	# 注意：固定种子下重试必须更换种子，否则会生成同一棋盘导致无限递归。
	if board.is_solved():
		var next_seed := seed_value + 1 if seed_value >= 0 else seed_value
		return scramble(board_size, moves, next_seed)
	return board

## 基于日期的确定性种子
static func daily_seed(board_size: int) -> int:
	var d := Time.get_date_dict_from_system()
	return hash("%d-%d-%d-%d" % [d.year, d.month, d.day, board_size])

static func today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]
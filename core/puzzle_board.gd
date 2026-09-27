class_name PuzzleBoard
extends RefCounted
## 数字华容道的棋盘逻辑。不依赖任何节点/渲染，可单独单元测试。
## 索引规则：行优先，index = row * size + col。

var size: int = 4
var tiles: Array[int] = []
var empty_index: int = 0

func _init(board_size: int = 4) -> void:
	size = board_size
	reset()

func total() -> int:
	return size * size

func reset() -> void:
	tiles.clear()
	for i in range(1, total()):
		tiles.append(i)
	tiles.append(0)
	empty_index = total() - 1

func is_solved() -> bool:
	for i in range(total() - 1):
		if tiles[i] != i + 1:
			return false
	return tiles[total() - 1] == 0

func neighbors(idx: int) -> Array[int]:
	var row := int(idx / size)
	var col := idx % size
	var res: Array[int] = []
	if row > 0: res.append(idx - size)
	if row < size - 1: res.append(idx + size)
	if col > 0: res.append(idx - 1)
	if col < size - 1: res.append(idx + 1)
	return res

func can_move(idx: int) -> bool:
	if idx < 0 or idx >= total():
		return false
	var r1 := int(idx / size)
	var c1 := idx % size
	var r2 := int(empty_index / size)
	var c2 := empty_index % size
	return absi(r1 - r2) + absi(c1 - c2) == 1

func move(idx: int) -> bool:
	if not can_move(idx):
		return false
	tiles[empty_index] = tiles[idx]
	tiles[idx] = 0
	empty_index = idx
	return true

func manhattan() -> int:
	var d := 0
	for i in range(total()):
		var v := tiles[i]
		if v == 0:
			continue
		var target := v - 1
		d += absi(int(i / size) - int(target / size)) + absi(i % size - target % size)
	return d

func find_value(value: int) -> int:
	return tiles.find(value)

func clone() -> PuzzleBoard:
	var b := PuzzleBoard.new(size)
	b.tiles = tiles.duplicate()
	b.empty_index = empty_index
	return b

func to_dict() -> Dictionary:
	return {"size": size, "tiles": tiles.duplicate(), "empty": empty_index}

static func from_dict(d: Dictionary) -> PuzzleBoard:
	var b := PuzzleBoard.new(int(d.get("size", 4)))
	var arr: Array = d.get("tiles", [])
	b.tiles.clear()
	for v in arr:
		b.tiles.append(int(v))
	b.empty_index = int(d.get("empty", b.total() - 1))
	return b

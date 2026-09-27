extends Node
## 所有持久化数据统一经由这里读写，避免多文件冲突。

const SAVE_PATH     := "user://klotski_save.json"
const BACKUP_PATH   := "user://klotski_save.bak.json"
const SAVE_VERSION  := 1
const AUTOSAVE_DELAY := 1.0

var data: Dictionary = {}

var _dirty: bool = false
var _timer: float = 0.0

func _ready() -> void:
	load_from_disk()

func _process(delta: float) -> void:
	if not _dirty:
		return
	_timer += delta
	if _timer >= AUTOSAVE_DELAY:
		save_to_disk()

## 获取（并按需创建）一个子段，返回的是引用，修改后请调用 mark_dirty()
func section(section_name: String) -> Dictionary:
	if not data.has(section_name) or typeof(data[section_name]) != TYPE_DICTIONARY:
		data[section_name] = {}
	return data[section_name]

func mark_dirty() -> void:
	_dirty = true
	_timer = 0.0

## force = true 时即使没有未保存的改动也强制写盘。
func save_now(force: bool = false) -> void:
	if _dirty or force:
		save_to_disk()

func load_from_disk() -> void:
	data = {"version": SAVE_VERSION}
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("[SaveManager] 无法打开存档文件")
		return
	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("[SaveManager] 存档损坏，尝试读取备份")
		_load_backup()
		return
	data = parsed
	data["version"] = SAVE_VERSION

func _load_backup() -> void:
	if not FileAccess.file_exists(BACKUP_PATH):
		return
	var f := FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		data = parsed

func save_to_disk() -> void:
	_dirty = false
	_timer = 0.0

	if FileAccess.file_exists(SAVE_PATH):
		var old := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if old:
			var old_text := old.get_as_text()
			old.close()
			var bak := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
			if bak:
				bak.store_string(old_text)
				bak.close()

	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] 存档写入失败: " + str(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

func wipe_all() -> void:
	data = {"version": SAVE_VERSION}
	save_to_disk()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if _dirty:
			save_to_disk()

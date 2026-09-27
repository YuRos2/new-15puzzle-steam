extends Node
## 所有跨系统通信都经过这里，各模块之间不直接互相引用。

# ── 游戏逻辑 ─────────────────────────────
@warning_ignore("unused_signal")
signal game_started(mode: int, size: int)
@warning_ignore("unused_signal")
signal board_reset(size: int)
@warning_ignore("unused_signal")
signal tile_moved(from_index: int, to_index: int, value: int)
@warning_ignore("unused_signal")
signal move_committed(steps: int)
@warning_ignore("unused_signal")
signal move_rejected()
@warning_ignore("unused_signal")
signal move_undone(steps: int)
@warning_ignore("unused_signal")
signal hint_shown(index: int)
@warning_ignore("unused_signal")
signal timer_updated(elapsed: float, remain: float)
@warning_ignore("unused_signal")
signal game_finished(result: Dictionary)

# ── 元游戏 ───────────────────────────────
@warning_ignore("unused_signal")
signal record_broken(key: String, value: float)
@warning_ignore("unused_signal")
signal achievement_unlocked(id: String)
@warning_ignore("unused_signal")
signal stats_changed()
@warning_ignore("unused_signal")
signal daily_status_changed()

# ── 表现层 ───────────────────────────────
@warning_ignore("unused_signal")
signal settings_changed(key: String, value: Variant)
@warning_ignore("unused_signal")
signal theme_changed(theme_id: int)
@warning_ignore("unused_signal")
signal request_toast(text: String, kind: int)

extends Node
## 音效由程序化波形生成，无需外部资源；背景音乐为可选资源文件。

var _sfx: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _next: int = 0
var _sfx_linear: float = 1.0
var _music_linear: float = 1.0

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)

	for i in range(8):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_apply_volumes()
	EventBus.settings_changed.connect(_on_setting_changed)

func _on_setting_changed(key: String, _v: Variant) -> void:
	if key in ["master_volume", "music_volume", "sfx_volume", "mute"]:
		_apply_volumes()

func _apply_volumes() -> void:
	var master := SettingsManager.get_float("master_volume")
	var muted := SettingsManager.get_bool("mute")
	_sfx_linear   = 0.0 if muted else master * SettingsManager.get_float("sfx_volume")
	_music_linear = 0.0 if muted else master * SettingsManager.get_float("music_volume")
	_music.volume_db = linear_to_db(maxf(_music_linear, 0.0001))

func play_sfx(name: String, pitch: float = 1.0) -> void:
	if _sfx_linear <= 0.001:
		return
	var stream: AudioStream = _sfx_for(name)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = linear_to_db(clampf(_sfx_linear, 0.0001, 1.0))
	p.play()

func play_music(path: String) -> void:
	if _music.playing:
		return
	if not ResourceLoader.exists(path):
		return
	_music.stream = load(path)
	_music.play()

func stop_music() -> void:
	_music.stop()

# ── 波形合成（按需生成并缓存，避免启动时一次性合成全部音效） ──

func _sfx_for(name: String) -> AudioStream:
	if _sfx.has(name):
		return _sfx[name]
	var stream: AudioStream = null
	match name:
		"move":        stream = _tone(520.0, 0.06, 0.32, 0)
		"invalid":     stream = _tone(170.0, 0.10, 0.28, 1)
		"undo":        stream = _tone(340.0, 0.08, 0.28, 0)
		"hint":        stream = _tone(900.0, 0.12, 0.22, 0)
		"click":       stream = _tone(660.0, 0.04, 0.20, 0)
		"win":         stream = _chord([523.25, 659.25, 783.99, 1046.50], 0.55, 0.28)
		"lose":        stream = _chord([392.00, 329.63, 261.63], 0.65, 0.26)
		"achievement": stream = _chord([783.99, 987.77, 1318.51], 0.45, 0.28)
	if stream != null:
		_sfx[name] = stream
	return stream

func _tone(freq: float, dur: float, amp: float, wave: int, rate: int = 22050) -> AudioStreamWAV:
	var count := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(rate)
		var env := pow(1.0 - t / dur, 2.0)
		var s := 0.0
		match wave:
			1: s = 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
			2: s = 2.0 * fmod(t * freq, 1.0) - 1.0
			_: s = sin(TAU * freq * t)
		s = clampf(s * env * amp, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(s * 32767.0))
	return _wrap_wav(bytes, rate)

func _chord(freqs: Array, dur: float, amp: float, rate: int = 22050) -> AudioStreamWAV:
	var count := int(rate * dur)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var per := amp / float(freqs.size())
	for i in range(count):
		var t := float(i) / float(rate)
		var env := pow(1.0 - t / dur, 1.6)
		var s := 0.0
		for f in freqs:
			s += sin(TAU * float(f) * t)
		s = clampf(s * env * per, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(s * 32767.0))
	return _wrap_wav(bytes, rate)

func _wrap_wav(bytes: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav
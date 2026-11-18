extends Control
## 气破 · Q版 双人同屏回合制小游戏
## 攻 / 防 / 聚气 / 破防，气大于护盾就能一击获胜。

const MAX_HEARTS := 3
const MAX_QI := 5
const MAX_SHIELD := 3
const SKILL_COST := 3

const C_TEXT := Color("#5d4a43")
const C_MUTED := Color("#94827a")
const C_GOLD := Color("#f5b942")
const C_P1 := Color("#4ea8ff")
const C_P2 := Color("#ff7fa5")
const C_ATTACK := Color("#ff7b72")
const C_DEFEND := Color("#5cb8ff")
const C_CHARGE := Color("#ffc94a")
const C_SKILL := Color("#b18cff")
const C_HEART := Color("#ff6b81")

## 联机服务器地址（部署后改这里，或在联机界面直接填）
const DEFAULT_SERVER := "ws://127.0.0.1:8080"
const NetClient := preload("res://scripts/net_client.gd")


# ---------------------------------------------------------------------------
# 绘制组件
# ---------------------------------------------------------------------------
class SkyBackground extends Control:
	var _clouds: Array[Dictionary] = []
	var _petals: Array[Dictionary] = []
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
		for i in 6:
			_clouds.append({
				"x": randf_range(-0.1, 1.0),
				"y": randf_range(0.10, 0.36),
				"s": randf_range(0.75, 1.35),
				"v": randf_range(0.004, 0.011),
			})
		for i in 34:
			_petals.append({
				"x": randf(),
				"y": randf(),
				"s": randf_range(2.0, 4.8),
				"v": randf_range(0.014, 0.040),
				"a": randf_range(0.25, 0.65),
			})

	func _process(delta: float) -> void:
		_t += delta
		for c in _clouds:
			c["x"] = float(c["x"]) + float(c["v"]) * delta
			if float(c["x"]) > 1.18:
				c["x"] = -0.18
		for p in _petals:
			p["y"] = float(p["y"]) + float(p["v"]) * delta
			p["x"] = float(p["x"]) + sin(_t * 0.7 + float(p["y"]) * 9.0) * 0.0006
			if float(p["y"]) > 1.04:
				p["y"] = -0.04
				p["x"] = randf()
		queue_redraw()

	func _draw() -> void:
		var s := size
		if s.x < 10.0 or s.y < 10.0:
			return
		# 天空
		var top := Color("#aee7ff")
		var bottom := Color("#fff4d8")
		var bands := 32
		for i in bands:
			var t := float(i) / float(bands - 1)
			draw_rect(Rect2(0.0, s.y * t, s.x, s.y / float(bands) + 2.0), top.lerp(bottom, t))
		# 太阳
		var sun := Vector2(s.x * 0.88, s.y * 0.15)
		draw_circle(sun, 86.0, Color(1.0, 0.97, 0.72, 0.10))
		draw_circle(sun, 62.0, Color(1.0, 0.94, 0.58, 0.28))
		draw_circle(sun, 46.0, Color(1.0, 0.88, 0.42))
		for i in 10:
			var a := TAU * float(i) / 10.0 + _t * 0.05
			draw_line(sun + Vector2(cos(a), sin(a)) * 55.0, sun + Vector2(cos(a), sin(a)) * 67.0, Color(1.0, 0.88, 0.46, 0.45), 3.0, true)
		# 云朵
		for c in _clouds:
			_draw_cloud(Vector2(float(c["x"]) * s.x, float(c["y"]) * s.y), float(c["s"]))
		# 远山
		draw_circle(Vector2(s.x * 0.10, s.y * 0.97), s.y * 0.36, Color("#b7e8ad"))
		draw_circle(Vector2(s.x * 0.40, s.y * 1.00), s.y * 0.34, Color("#a5df9f"))
		draw_circle(Vector2(s.x * 0.73, s.y * 0.98), s.y * 0.37, Color("#b7e8ad"))
		draw_circle(Vector2(s.x * 1.02, s.y * 1.02), s.y * 0.35, Color("#a5df9f"))
		draw_circle(Vector2(s.x * 0.50, s.y * 1.08), s.y * 0.33, Color("#8fd58f"))
		# 比舞台
		_ellipse(Vector2(s.x * 0.50, s.y * 0.66), Vector2(s.x * 0.33, s.y * 0.10), Color(1, 1, 1, 0.30))
		_ellipse(Vector2(s.x * 0.50, s.y * 0.675), Vector2(s.x * 0.28, s.y * 0.07), Color("#d8f5bc"))
		# 小花
		for i in 18:
			var fx := s.x * (0.04 + float(i) * 0.055)
			var fy := s.y * (0.73 + 0.05 * sin(float(i) * 2.2))
			draw_circle(Vector2(fx, fy), 3.0, Color("#fff0a8"))
		# 花瓣
		for p in _petals:
			draw_circle(Vector2(float(p["x"]) * s.x, float(p["y"]) * s.y), float(p["s"]), Color(1.0, 0.55, 0.70, float(p["a"])))

	func _draw_cloud(pos: Vector2, scale: float) -> void:
		var white := Color(1, 1, 1, 0.86)
		var shade := Color(0.75, 0.90, 1.0, 0.55)
		draw_circle(pos + Vector2(-38, 8) * scale, 28.0 * scale, shade)
		draw_circle(pos + Vector2(38, 10) * scale, 24.0 * scale, shade)
		draw_circle(pos + Vector2(-22, -8) * scale, 30.0 * scale, white)
		draw_circle(pos + Vector2(20, -13) * scale, 36.0 * scale, white)
		draw_circle(pos + Vector2(54, 2) * scale, 24.0 * scale, white)

	func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 40:
			var a := TAU * float(i) / 40.0
			pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
		draw_colored_polygon(pts, color)


class Chibi extends Control:
	var index := 0
	var accent := Color.WHITE
	var hair := Color("#4a3834")
	var outfit := Color.WHITE
	var skin := Color("#ffe3c8")
	var state := "idle"
	var active := false
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func play_state(s: String, dur: float = 0.45) -> void:
		state = s
		queue_redraw()
		if dur > 0.0:
			var tw := create_tween()
			tw.tween_interval(dur)
			tw.tween_callback(func() -> void:
				if state == s:
					state = "idle"
					queue_redraw()
			)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 20.0 or h < 20.0:
			return
		var cx := w * 0.5
		var ground := h * 0.92
		var bob := sin(_t * 2.4 + float(index) * 1.7) * 3.0
		if active:
			for i in range(5, 0, -1):
				draw_circle(Vector2(cx, ground - 8.0), 54.0 + float(i) * 9.0, Color(accent.r, accent.g, accent.b, 0.016))
			draw_arc(Vector2(cx, ground - 8.0), 68.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.38), 2.0, true)
			draw_circle(Vector2(cx, ground - 102.0 + bob), 4.0, Color(accent.r, accent.g, accent.b, 0.75))
		_ellipse(Vector2(cx, ground), Vector2(62.0, 15.0), Color(0.18, 0.30, 0.18, 0.18))
		var body_y := ground - 54.0 + bob
		# 腿和鞋
		draw_line(Vector2(cx - 15.0, body_y + 18.0), Vector2(cx - 19.0, ground - 8.0), Color("#5a463e"), 9.0, true)
		draw_line(Vector2(cx + 15.0, body_y + 18.0), Vector2(cx + 19.0, ground - 8.0), Color("#5a463e"), 9.0, true)
		draw_circle(Vector2(cx - 19.0, ground - 5.0), 9.0, Color("#7c5c50"))
		draw_circle(Vector2(cx + 19.0, ground - 5.0), 9.0, Color("#7c5c50"))
		# 身体
		draw_circle(Vector2(cx, body_y - 8.0), 39.0, outfit)
		draw_rect(Rect2(cx - 37.0, body_y - 8.0, 74.0, 34.0), outfit, true)
		draw_circle(Vector2(cx, body_y + 4.0), 22.0, Color(1, 1, 1, 0.22))
		# 手臂
		draw_line(Vector2(cx - 30.0, body_y - 12.0), Vector2(cx - 48.0, body_y + 17.0), outfit, 12.0, true)
		draw_line(Vector2(cx + 30.0, body_y - 12.0), Vector2(cx + 48.0, body_y + 17.0), outfit, 12.0, true)
		draw_circle(Vector2(cx - 49.0, body_y + 20.0), 9.0, skin)
		draw_circle(Vector2(cx + 49.0, body_y + 20.0), 9.0, skin)
		# 头
		var head := Vector2(cx, body_y - 88.0)
		draw_circle(head + Vector2(0, -3), 68.0, hair)
		draw_circle(head + Vector2(-58, 8), 14.0, hair)
		draw_circle(head + Vector2(58, 8), 14.0, hair)
		draw_circle(head + Vector2(0, 7), 58.0, skin)
		# 刘海
		draw_circle(head + Vector2(-31, -31), 23.0, hair)
		draw_circle(head + Vector2(0, -37), 25.0, hair)
		draw_circle(head + Vector2(31, -31), 23.0, hair)
		# 发饰 / 头带
		if index == 0:
			draw_arc(head + Vector2(0, 0), 58.0, -2.70, -0.44, 32, accent, 9.0, true)
			draw_circle(head + Vector2(52, -38), 7.0, accent.lightened(0.25))
		else:
			draw_circle(head + Vector2(-57, -52), 23.0, hair)
			draw_circle(head + Vector2(57, -52), 23.0, hair)
			draw_circle(head + Vector2(-57, -52), 7.0, accent)
			draw_circle(head + Vector2(57, -52), 7.0, accent)
		# 表情
		if state == "hurt" or state == "lose":
			_cross_eye(head + Vector2(-22, 6))
			_cross_eye(head + Vector2(22, 6))
			draw_circle(head + Vector2(0, 30), 7.0, Color("#7b3f3f"))
		elif state == "win":
			_happy_eye(head + Vector2(-22, 4))
			_happy_eye(head + Vector2(22, 4))
			draw_arc(head + Vector2(0, 23), 10.0, 0.12 + PI, 0.88 + PI, 16, Color("#6b4540"), 2.5, true)
		else:
			_normal_eye(head + Vector2(-22, 4))
			_normal_eye(head + Vector2(22, 4))
			if state == "attack" or state == "skill":
				draw_line(head + Vector2(-35, -13), head + Vector2(-12, -8), Color("#6b4540"), 3.0, true)
				draw_line(head + Vector2(35, -13), head + Vector2(12, -8), Color("#6b4540"), 3.0, true)
				draw_circle(head + Vector2(0, 26), 6.0, Color("#7b3f3f"))
			else:
				draw_arc(head + Vector2(0, 23), 8.0, 0.15 * PI, 0.85 * PI, 14, Color("#6b4540"), 2.2, true)
		draw_circle(head + Vector2(-39, 20), 8.0, Color(1.0, 0.45, 0.58, 0.35))
		draw_circle(head + Vector2(39, 20), 8.0, Color(1.0, 0.45, 0.58, 0.35))

	func _normal_eye(c: Vector2) -> void:
		draw_circle(c, 8.5, Color("#3e2e2b"))
		draw_circle(c + Vector2(-2.5, -2.8), 2.8, Color.WHITE)

	func _cross_eye(c: Vector2) -> void:
		draw_line(c + Vector2(-7, -7), c + Vector2(7, 7), Color("#3e2e2b"), 3.0, true)
		draw_line(c + Vector2(7, -7), c + Vector2(-7, 7), Color("#3e2e2b"), 3.0, true)

	func _happy_eye(c: Vector2) -> void:
		draw_line(c + Vector2(-8, 4), c + Vector2(0, -4), Color("#3e2e2b"), 3.4, true)
		draw_line(c + Vector2(0, -4), c + Vector2(8, 4), Color("#3e2e2b"), 3.4, true)

	func _ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 32:
			var a := TAU * float(i) / 32.0
			pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
		draw_colored_polygon(pts, color)


class PipRow extends Control:
	var kind := "heart"
	var value := 0
	var max_value := 3
	var accent := Color.WHITE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func set_data(v: int, m: int) -> void:
		value = v
		max_value = maxi(1, m)
		queue_redraw()

	func _draw() -> void:
		if size.x < 10.0:
			return
		var spacing := minf(28.0, size.x / float(max_value))
		var cy := size.y * 0.5
		for i in max_value:
			var c := Vector2(spacing * 0.5 + float(i) * spacing, cy)
			var filled := i < value
			if kind == "heart":
				_heart(c, 9.5, filled)
			elif kind == "qi":
				_orb(c, 8.5, filled)
			else:
				_shield(c, 9.0, filled)

	func _heart(c: Vector2, s: float, filled: bool) -> void:
		var pts := PackedVector2Array()
		for i in 32:
			var t := TAU * float(i) / 32.0
			var x := 16.0 * pow(sin(t), 3.0)
			var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
			pts.append(c + Vector2(x, y) * (s / 16.0))
		if filled:
			draw_colored_polygon(pts, accent)
		else:
			draw_colored_polygon(pts, Color(1, 1, 1, 0.65))
			pts.append(pts[0])
			draw_polyline(pts, Color(accent.r, accent.g, accent.b, 0.35), 1.5, true)

	func _orb(c: Vector2, r: float, filled: bool) -> void:
		if filled:
			draw_circle(c, r, accent)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.28, Color(1, 1, 1, 0.75))
		else:
			draw_circle(c, r, Color(1, 1, 1, 0.55))
			draw_arc(c, r, 0.0, TAU, 28, Color(accent.r, accent.g, accent.b, 0.35), 1.5, true)

	func _shield(c: Vector2, s: float, filled: bool) -> void:
		var pts := PackedVector2Array([
			c + Vector2(0, -s),
			c + Vector2(s, 0),
			c + Vector2(0, s),
			c + Vector2(-s, 0),
		])
		if filled:
			draw_colored_polygon(pts, accent)
		else:
			draw_colored_polygon(pts, Color(1, 1, 1, 0.55))
			pts.append(pts[0])
			draw_polyline(pts, Color(accent.r, accent.g, accent.b, 0.35), 1.5, true)


class Confetti extends Control:
	var pieces: Array[Dictionary] = []
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var colors := [Color("#ff7fa5"), Color("#4ea8ff"), Color("#ffc94a"), Color("#b18cff"), Color("#7ed08a")]
		for i in 64:
			pieces.append({
				"x": randf(), "y": randf_range(-0.2, 1.0),
				"v": randf_range(0.08, 0.20), "r": randf_range(4.0, 9.0),
				"a": randf_range(0.5, 1.0), "c": colors[randi() % colors.size()],
			})
		set_process(true)

	func _process(delta: float) -> void:
		_t += delta
		for p in pieces:
			p["y"] = float(p["y"]) + float(p["v"]) * delta
			if float(p["y"]) > 1.05:
				p["y"] = -0.05
				p["x"] = randf()
		queue_redraw()

	func _draw() -> void:
		for p in pieces:
			var pos := Vector2(float(p["x"]) * size.x, float(p["y"]) * size.y)
			var r := float(p["r"])
			draw_rect(Rect2(pos, Vector2(r, r * 0.6)), Color(float(p["c"].r), float(p["c"].g), float(p["c"].b), float(p["a"])))


class CuteAudio extends Node:
	const RATE := 22050
	const TAU2 := 6.283185307179586
	var _pool: Array[AudioStreamPlayer] = []
	var _sounds: Dictionary = {}
	var _idx := 0

	func _ready() -> void:
		for i in 5:
			var p := AudioStreamPlayer.new()
			add_child(p)
			_pool.append(p)
		_sounds["click"] = _tone(760.0, 0.055, 0.20)
		_sounds["attack"] = _seq([330.0, 240.0, 180.0], 0.05, 0.20)
		_sounds["hit"] = _seq([180.0, 130.0], 0.07, 0.18)
		_sounds["guard"] = _seq([440.0, 660.0], 0.07, 0.15)
		_sounds["charge"] = _seq([523.0, 659.0, 784.0], 0.065, 0.16)
		_sounds["skill"] = _seq([880.0, 660.0, 440.0, 220.0], 0.09, 0.20)
		_sounds["win"] = _seq([523.0, 659.0, 784.0, 1046.0], 0.13, 0.18)
		_sounds["error"] = _seq([220.0, 165.0], 0.08, 0.16)

	func play(sfx_name: String) -> void:
		if not _sounds.has(sfx_name) or _pool.is_empty():
			return
		var p := _pool[_idx]
		_idx = (_idx + 1) % _pool.size()
		p.stream = _sounds[sfx_name]
		p.play()

	func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
		var data := PackedByteArray()
		data.resize(samples.size() * 2)
		for i in samples.size():
			data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
		var wav := AudioStreamWAV.new()
		wav.format = AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate = RATE
		wav.stereo = false
		wav.data = data
		return wav

	func _tone(freq: float, dur: float, vol: float) -> AudioStreamWAV:
		var n := int(RATE * dur)
		var arr := PackedFloat32Array()
		arr.resize(n)
		for i in n:
			var t := float(i) / RATE
			var env := minf(t / 0.008, 1.0) * pow(maxf(1.0 - t / dur, 0.0), 2.0)
			arr[i] = sin(TAU2 * freq * t) * env * vol
		return _wav(arr)

	func _seq(freqs: Array, note: float, vol: float) -> AudioStreamWAV:
		var per := int(RATE * note)
		var arr := PackedFloat32Array()
		arr.resize(per * freqs.size())
		for k in freqs.size():
			for i in per:
				var t := float(i) / RATE
				var env := minf(t / 0.005, 1.0) * pow(maxf(1.0 - t / note, 0.0), 1.4)
				arr[k * per + i] = sin(TAU2 * float(freqs[k]) * t) * env * vol
		return _wav(arr)


# ---------------------------------------------------------------------------
# 数据与界面引用
# ---------------------------------------------------------------------------
var players: Array[Dictionary] = [
	{"name": "小玄", "hp": MAX_HEARTS, "qi": 0, "shield": 0, "accent": C_P1},
	{"name": "小赤", "hp": MAX_HEARTS, "qi": 0, "shield": 0, "accent": C_P2},
]

var current := 0
var first_player := 0
var round_no := 1
var resolving := false
var game_over := false
## select: 当前玩家选招 / handoff: 交接遮挡 / reveal: 亮招 / resolve: 结算 / over: 结束
var phase := "select"
## 本回合双方各自选定的招式，空串表示还没选
var pending: Array[String] = ["", ""]

## hotseat：单机同屏；online：联网对战
var mode := "hotseat"
## 联机时本客户端控制哪一方（0=小玄，1=小赤）
var my_seat := 0
var room_code := ""
var _net
var _pending_net_cmd: Dictionary = {}
var _my_rematch := false
var _opp_rematch := false
var _result_status: Label
var _result_rematch_btn: Button
var _top_btn: Button
var _lobby_status: Label
var _lobby_server_edit: LineEdit
var _lobby_code_edit: LineEdit

var _font_body: Font
var _font_title: Font
var _audio: CuteAudio

var _panels: Array[PanelContainer] = []
var _active_tags: Array[Label] = []
var _heart_rows: Array[PipRow] = []
var _qi_rows: Array[PipRow] = []
var _shield_rows: Array[PipRow] = []
var _chibis: Array[Chibi] = []
var _cards: Dictionary = {}

var _turn_panel: PanelContainer
var _turn_label: Label
var _round_label: Label
var _fx_layer: Control
var _overlay_layer: Control


# ---------------------------------------------------------------------------
# 启动
# ---------------------------------------------------------------------------
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_fonts()
	var th := Theme.new()
	th.default_font = _font_body
	th.default_font_size = 16
	theme = th
	var bg := SkyBackground.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_header()
	_panels.resize(2)
	_active_tags.resize(2)
	_heart_rows.resize(2)
	_qi_rows.resize(2)
	_shield_rows.resize(2)
	_chibis.resize(2)
	_build_player_panel(0)
	_build_player_panel(1)
	_build_arena()
	_build_dock()
	_fx_layer = Control.new()
	_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx_layer)
	_overlay_layer = Control.new()
	_overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_layer)
	_audio = CuteAudio.new()
	add_child(_audio)
	_net = NetClient.new()
	add_child(_net)
	_net.connected.connect(_on_net_connected)
	_net.disconnected.connect(_on_net_disconnected)
	_net.message_received.connect(_on_net_message)
	phase = "menu"
	_update_ui()
	_show_mode_menu()


func _build_fonts() -> void:
	var body := SystemFont.new()
	body.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "SimHei", "Noto Sans CJK SC"])
	body.font_weight = 500
	_font_body = body
	var title := SystemFont.new()
	title.font_names = PackedStringArray(["YouYuan", "Microsoft YaHei UI", "Microsoft YaHei", "SimHei"])
	title.font_weight = 700
	_font_title = title


func _build_header() -> void:
	var badge := _label("同 时 出 招", 13, Color("#7b5aa6"))
	badge.position = Vector2(24, 20)
	badge.size = Vector2(106, 28)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_stylebox_override("normal", _flat(Color(1, 0.96, 0.86, 0.88), Color("#e7cfa8"), 1, 14))
	add_child(badge)

	var title := _label("气 破 · Q 版", 44, Color("#6b4b8a"), _font_title)
	title.position = Vector2(0, 7)
	title.size = Vector2(1280, 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.95))
	title.add_theme_constant_override("outline_size", 7)
	add_child(title)

	var sub := _label("各自选招 · 一起亮招结算 · 气 大 于 盾 就 破 防", 14, Color("#8a746a"))
	sub.position = Vector2(0, 58)
	sub.size = Vector2(1280, 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	_round_label = _label("第 1 回合", 13, Color("#8a746a"))
	_round_label.position = Vector2(590, 83)
	_round_label.size = Vector2(100, 26)
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_round_label.add_theme_stylebox_override("normal", _flat(Color(1, 1, 1, 0.60), Color(1, 1, 1, 0.90), 1, 13))
	add_child(_round_label)

	var again := _small_button("重 开", Color("#7b5aa6"))
	again.position = Vector2(1162, 18)
	again.size = Vector2(88, 34)
	again.pressed.connect(_restart_match)
	add_child(again)
	_top_btn = again


func _build_player_panel(idx: int) -> void:
	var p: Dictionary = players[idx]
	var accent: Color = p["accent"]
	var panel := PanelContainer.new()
	panel.position = Vector2(24.0 if idx == 0 else 974.0, 118.0)
	panel.size = Vector2(282, 184)
	panel.add_theme_stylebox_override("panel", _panel_style(accent, idx == current))
	add_child(panel)
	_panels[idx] = panel
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	margin.add_child(vb)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	var name_label := _label(str(p["name"]), 28, accent, _font_title)
	top.add_child(name_label)
	var who := _label("玩家 %d" % (idx + 1), 12, C_MUTED)
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(who)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var tag := _label("轮到啦！", 12, accent)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.add_theme_stylebox_override("normal", _flat(Color(accent.r, accent.g, accent.b, 0.14), Color(accent.r, accent.g, accent.b, 0.28), 1, 9))
	tag.custom_minimum_size = Vector2(68, 24)
	tag.visible = false
	top.add_child(tag)
	_active_tags[idx] = tag
	vb.add_child(top)
	vb.add_child(_stat_row("气血", "heart", C_HEART, idx, _heart_rows))
	vb.add_child(_stat_row("气", "qi", C_CHARGE, idx, _qi_rows))
	vb.add_child(_stat_row("护盾", "shield", C_DEFEND, idx, _shield_rows))


func _stat_row(caption: String, kind: String, color: Color, idx: int, store: Array[PipRow]) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	var l := _label(caption, 13, C_MUTED)
	l.custom_minimum_size = Vector2(36, 22)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var pips := PipRow.new()
	pips.kind = kind
	pips.accent = color
	pips.custom_minimum_size = Vector2(0, 24)
	pips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(pips)
	store[idx] = pips
	return h


func _build_arena() -> void:
	var p1 := Chibi.new()
	p1.position = Vector2(310, 145)
	p1.size = Vector2(240, 300)
	p1.index = 0
	p1.accent = C_P1
	p1.hair = Color("#3d4b66")
	p1.outfit = Color("#8fd0ff")
	add_child(p1)
	_chibis[0] = p1
	var p2 := Chibi.new()
	p2.position = Vector2(730, 145)
	p2.size = Vector2(240, 300)
	p2.index = 1
	p2.accent = C_P2
	p2.hair = Color("#5a3a48")
	p2.outfit = Color("#ffc1d2")
	add_child(p2)
	_chibis[1] = p2

	var vs := _label("VS", 24, Color("#ffffff"), _font_title)
	vs.position = Vector2(608, 252)
	vs.size = Vector2(64, 64)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.add_theme_stylebox_override("normal", _flat(Color("#f5b942"), Color("#ffffff"), 3, 32))
	add_child(vs)

	_turn_panel = PanelContainer.new()
	_turn_panel.position = Vector2(448, 456)
	_turn_panel.size = Vector2(384, 46)
	_turn_panel.add_theme_stylebox_override("panel", _flat(Color(0.30, 0.66, 1.0, 0.95), Color(1, 1, 1, 0.9), 2, 23))
	add_child(_turn_panel)
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 16)
	tm.add_theme_constant_override("margin_right", 16)
	_turn_panel.add_child(tm)
	_turn_label = _label("轮到 小玄 出招！", 21, Color.WHITE, _font_title)
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tm.add_child(_turn_label)


func _build_dock() -> void:
	var dock := PanelContainer.new()
	dock.position = Vector2(70, 520)
	dock.size = Vector2(1140, 178)
	dock.add_theme_stylebox_override("panel", _flat(Color(1, 0.99, 0.95, 0.94), Color("#f0d9b5"), 2, 22))
	add_child(dock)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	dock.add_child(margin)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 7)
	margin.add_child(vb)
	var head := HBoxContainer.new()
	var ht := _label("各 自 出 招 ！", 18, C_TEXT, _font_title)
	head.add_child(ht)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var hint := _label("鼠标点击  ·  键盘 1 / 2 / 3 / 4", 12, C_MUTED)
	head.add_child(hint)
	vb.add_child(head)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	_add_card(row, "attack", "攻", "普通攻击", "打掉 1 颗心\n震散 1 点气", "无消耗", C_ATTACK, "1")
	_add_card(row, "defend", "防", "抱盾防守", "护盾 +1\n最多 3 点", "无消耗", C_DEFEND, "2")
	_add_card(row, "charge", "聚", "聚气蓄力", "气 +1\n最多 5 点", "无消耗", C_CHARGE, "3")
	_add_card(row, "skill", "破", "破防一击", "气 > 护盾\n直接获胜！", "需 3 气", C_SKILL, "4")


func _add_card(row: HBoxContainer, kind: String, glyph: String, title: String, desc: String, cost: String, accent: Color, key: String) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 112)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _card_style(accent, "normal"))
	b.add_theme_stylebox_override("hover", _card_style(accent, "hover"))
	b.add_theme_stylebox_override("pressed", _card_style(accent, "pressed"))
	b.add_theme_stylebox_override("disabled", _card_style(accent, "disabled"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func() -> void: _request_action(kind))
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	b.add_child(margin)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	margin.add_child(h)
	var icon := _label(glyph, 34, accent, _font_title)
	icon.custom_minimum_size = Vector2(54, 54)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_stylebox_override("normal", _flat(Color(accent.r, accent.g, accent.b, 0.12), Color(accent.r, accent.g, accent.b, 0.28), 2, 27))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(icon)
	var tv := VBoxContainer.new()
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", 1)
	h.add_child(tv)
	var tl := _label(title, 19, C_TEXT, _font_title)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(tl)
	var dl := _label(desc, 11, C_MUTED)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(dl)
	var cl := _label(cost, 11, accent)
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_child(cl)
	var kb := _label(key, 11, Color("#a89890"))
	kb.custom_minimum_size = Vector2(22, 22)
	kb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kb.add_theme_stylebox_override("normal", _flat(Color(1, 1, 1, 0.5), Color("#e3d4c0"), 1, 8))
	kb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(kb)
	row.add_child(b)
	_cards[kind] = {"button": b, "title": tl, "desc": dl, "cost": cl, "icon": icon, "accent": accent}


# ---------------------------------------------------------------------------
# 模式选择 / 联机大厅
# ---------------------------------------------------------------------------
func _clear_overlay() -> void:
	if _overlay_layer == null:
		return
	for c in _overlay_layer.get_children():
		c.queue_free()


func _clear_fx() -> void:
	if _fx_layer == null:
		return
	for c in _fx_layer.get_children():
		c.queue_free()


func _overlay_base(dim_color: Color) -> Control:
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = dim_color
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	return ov


func _pad(m: Control, l: int, r: int, t: int, b: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", l)
	margin.add_theme_constant_override("margin_right", r)
	margin.add_theme_constant_override("margin_top", t)
	margin.add_theme_constant_override("margin_bottom", b)
	m.add_child(margin)
	return margin


func _fade_in(ov: Control) -> void:
	ov.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(ov, "modulate:a", 1.0, 0.18)


func _show_mode_menu() -> void:
	_clear_overlay()
	mode = "hotseat"
	game_over = false
	phase = "menu"
	if _net != null:
		_net.close()
	if _top_btn != null:
		_top_btn.text = "重 开"
	_update_ui()
	var ov := _overlay_base(Color(1.0, 0.97, 0.90, 0.94))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 400)
	card.add_theme_stylebox_override("panel", _panel_style(C_GOLD, true))
	center.add_child(card)
	var margin := _pad(card, 30, 30, 26, 26)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 9)
	margin.add_child(vb)
	var title := _label("气 破 · Q 版", 40, Color("#6b4b8a"), _font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := _label("同 时 出 招 · 一 起 结 算", 15, C_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	vb.add_child(gap)
	var hot := _big_button("单 机 同 屏", C_P1)
	hot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hot.pressed.connect(func() -> void:
		_clear_overlay()
		_start_hotseat()
	)
	vb.add_child(hot)
	var online := _big_button("联 网 对 战", C_P2)
	online.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	online.pressed.connect(_show_online_lobby)
	vb.add_child(online)
	_overlay_layer.add_child(ov)
	_fade_in(ov)


func _start_hotseat() -> void:
	mode = "hotseat"
	if _net != null:
		_net.close()
	if _top_btn != null:
		_top_btn.text = "重 开"
	_reset_game(false)


func _show_online_lobby() -> void:
	_clear_overlay()
	mode = "online"
	phase = "menu"
	game_over = false
	var ov := _overlay_base(Color(1.0, 0.97, 0.90, 0.96))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 450)
	card.add_theme_stylebox_override("panel", _panel_style(C_P2, true))
	center.add_child(card)
	var margin := _pad(card, 30, 30, 24, 24)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)
	var title := _label("联 网 对 战", 32, C_P2, _font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var hint := _label("一人点「创建房间」，把 4 位房间码发给朋友；\n朋友填好房间码点「加入」即可。", 13, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hint)

	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 8)
	var sl := _label("服务器", 13, C_MUTED)
	sl.custom_minimum_size = Vector2(52, 0)
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	srow.add_child(sl)
	_lobby_server_edit = LineEdit.new()
	_lobby_server_edit.text = DEFAULT_SERVER
	_lobby_server_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lobby_server_edit.custom_minimum_size = Vector2(0, 34)
	srow.add_child(_lobby_server_edit)
	vb.add_child(srow)

	var create_btn := _big_button("创 建 房 间", C_P1)
	create_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	create_btn.pressed.connect(_online_create)
	vb.add_child(create_btn)

	var jrow := HBoxContainer.new()
	jrow.add_theme_constant_override("separation", 8)
	_lobby_code_edit = LineEdit.new()
	_lobby_code_edit.placeholder_text = "房间码"
	_lobby_code_edit.max_length = 4
	_lobby_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lobby_code_edit.custom_minimum_size = Vector2(0, 40)
	_lobby_code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	jrow.add_child(_lobby_code_edit)
	var join_btn := _big_button("加 入 房 间", C_P2)
	join_btn.custom_minimum_size = Vector2(150, 46)
	join_btn.pressed.connect(func() -> void: _online_join(_lobby_code_edit.text))
	jrow.add_child(join_btn)
	vb.add_child(jrow)

	_lobby_status = _label("", 13, Color("#8a746a"))
	_lobby_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_lobby_status)

	var back := _small_button("返 回", Color("#8a746a"))
	back.pressed.connect(_show_mode_menu)
	vb.add_child(back)
	_overlay_layer.add_child(ov)
	_fade_in(ov)


func _online_create() -> void:
	if _lobby_status != null:
		_lobby_status.text = "连接服务器中…"
	_net_connect_then({"t": "create"})


func _online_join(code: String) -> void:
	var c := code.strip_edges().to_upper()
	if c.length() < 4:
		if _lobby_status != null:
			_lobby_status.text = "请输入 4 位房间码"
		return
	if _lobby_status != null:
		_lobby_status.text = "加入房间 %s …" % c
	_net_connect_then({"t": "join", "room": c})


func _net_connect_then(cmd: Dictionary) -> void:
	_pending_net_cmd = cmd
	var url := DEFAULT_SERVER
	if _lobby_server_edit != null and _lobby_server_edit.text.strip_edges() != "":
		url = _lobby_server_edit.text.strip_edges()
	if _net.is_open():
		_net.send_json(cmd)
		_pending_net_cmd = {}
	else:
		_net.connect_to(url)


func _on_net_connected() -> void:
	if not _pending_net_cmd.is_empty():
		_net.send_json(_pending_net_cmd)
		_pending_net_cmd = {}


func _on_net_disconnected() -> void:
	if mode == "online" and phase != "menu" and not game_over:
		_online_peer_left()


func _on_net_message(d: Dictionary) -> void:
	var t := str(d.get("t", ""))
	match t:
		"created":
			room_code = str(d.get("room", ""))
			if _lobby_status != null:
				_lobby_status.text = "房间码：%s\n把房间码发给朋友，等待加入…" % room_code
		"start":
			room_code = str(d.get("room", room_code))
			_start_online_match(int(d.get("seat", 0)))
		"action":
			if not game_over:
				pending[1 - my_seat] = str(d.get("action", ""))
				if phase == "select" or phase == "waiting":
					if str(pending[my_seat]) != "":
						_start_resolve()
					else:
						_update_ui()
				# reveal / resolve 期间提前到达的招式先留在 pending，下一回合再用
		"rematch":
			_opp_rematch = true
			if _my_rematch:
				_start_online_match(my_seat)
			elif _result_status != null and is_instance_valid(_result_status):
				_result_status.text = "对手想再来一局！"
		"peer_left":
			_online_peer_left()
		"error":
			if _lobby_status != null and is_instance_valid(_lobby_status):
				_lobby_status.text = str(d.get("msg", "出错了"))


func _start_online_match(seat: int) -> void:
	mode = "online"
	my_seat = seat
	round_no = 1
	resolving = false
	game_over = false
	_my_rematch = false
	_opp_rematch = false
	_result_status = null
	_result_rematch_btn = null
	pending = ["", ""]
	for i in 2:
		players[i]["hp"] = MAX_HEARTS
		players[i]["qi"] = 0
		players[i]["shield"] = 0
		_chibis[i].play_state("idle", 0)
	_clear_fx()
	_clear_overlay()
	if _top_btn != null:
		_top_btn.text = "离 开"
	_online_begin_pick()


func _online_begin_pick() -> void:
	# 注意：不清空 pending，结算期间对手可能已提前发来下一回合的招式，要保留。
	current = my_seat
	phase = "select"
	resolving = false
	game_over = false
	_update_ui()


func _online_peer_left() -> void:
	if mode != "online":
		return
	game_over = true
	phase = "over"
	_show_notice("对手已离开或掉线", "返回大厅", _leave_online_to_menu)


func _leave_online_to_menu() -> void:
	if _net != null:
		_net.close()
	_show_mode_menu()


func _request_rematch() -> void:
	_my_rematch = true
	_net.send_json({"t": "rematch"})
	if _opp_rematch:
		_start_online_match(my_seat)
	elif _result_rematch_btn != null and is_instance_valid(_result_rematch_btn):
		_result_rematch_btn.text = "等 待 对 手…"
		_result_rematch_btn.disabled = true


func _show_notice(text: String, btn_text: String, cb: Callable) -> void:
	_clear_overlay()
	var ov := _overlay_base(Color(1.0, 0.96, 0.84, 0.82))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 220)
	card.add_theme_stylebox_override("panel", _panel_style(C_GOLD, true))
	center.add_child(card)
	var margin := _pad(card, 30, 30, 24, 24)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	margin.add_child(vb)
	var l := _label(text, 22, C_TEXT, _font_title)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	var b := _big_button(btn_text, C_GOLD)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void: cb.call())
	vb.add_child(b)
	_overlay_layer.add_child(ov)
	_fade_in(ov)


# ---------------------------------------------------------------------------
# 游戏流程
# ---------------------------------------------------------------------------
func _request_action(kind: String) -> void:
	if game_over or phase != "select":
		return
	# 联机：只控制自己这一方，选完把招式发给服务器，等对手的招一起结算
	if mode == "online":
		var me: Dictionary = players[my_seat]
		if kind == "skill" and int(me["qi"]) < SKILL_COST:
			_audio.play("error")
			_bounce(_chibis[my_seat])
			return
		_audio.play("click")
		pending[my_seat] = kind
		_net.send_json({"t": "action", "action": kind})
		if str(pending[0]) != "" and str(pending[1]) != "":
			_start_resolve()
		else:
			phase = "waiting"
			_update_ui()
		return
	# 单机同屏
	var p: Dictionary = players[current]
	if kind == "skill" and int(p["qi"]) < SKILL_COST:
		_audio.play("error")
		_bounce(_chibis[current])
		return
	_audio.play("click")
	pending[current] = kind
	if str(pending[0]) == "" or str(pending[1]) == "":
		# 一方已出招，遮住屏幕把设备交给另一方
		_show_handoff(1 - current)
	else:
		_start_resolve()


func _start_resolve() -> void:
	# 先把本回合双方招式快照下来并清空 pending，
	# 这样结算动画期间对手提前发来的下一回合招式不会误触发第二次结算。
	var acts: Array[String] = [str(pending[0]), str(pending[1])]
	pending = ["", ""]
	phase = "reveal"
	resolving = true
	_refresh_buttons()
	_update_ui()
	_turn_label.text = "%s「%s」  ·  %s「%s」" % [
		str(players[0]["name"]), _action_name(acts[0]),
		str(players[1]["name"]), _action_name(acts[1])
	]
	_audio.play("click")
	await get_tree().create_timer(0.95).timeout
	await _resolve_round(acts)


## 同时结算：先聚气/加盾，再破防，再普攻，最后一起结算伤害。
func _resolve_round(acts: Array) -> void:
	phase = "resolve"
	var spent := [0, 0]
	for i in 2:
		if str(acts[i]) == "skill":
			spent[i] = int(players[i]["qi"])

	# 1) 聚气与防守先生效（同一回合内就能挡下攻击 / 提升破防门槛）
	for i in 2:
		var p: Dictionary = players[i]
		match str(acts[i]):
			"defend":
				var gain := mini(1, MAX_SHIELD - int(p["shield"]))
				p["shield"] = int(p["shield"]) + gain
				_chibis[i].play_state("guard", 0.38)
				_bounce(_chibis[i])
				if gain > 0:
					_float_on(i, "+%d 护盾" % gain, C_DEFEND, 24)
				else:
					_float_on(i, "护盾满啦！", C_DEFEND, 18)
				_audio.play("guard")
			"charge":
				var gain := mini(1, MAX_QI - int(p["qi"]))
				p["qi"] = int(p["qi"]) + gain
				_chibis[i].play_state("charge", 0.38)
				_bounce(_chibis[i])
				if gain > 0:
					_float_on(i, "+%d 气" % gain, C_CHARGE, 24)
				else:
					_float_on(i, "气满啦！", C_CHARGE, 18)
				_audio.play("charge")
	# 破防消耗全部气（威力在选招时已锁定）
	for i in 2:
		if str(acts[i]) == "skill":
			players[i]["qi"] = 0
	_update_ui()
	await get_tree().create_timer(0.42).timeout

	var dmg := [0, 0]
	var instant: Array[bool] = [false, false]

	# 2) 破防：气 > 对手当前护盾 → 直接击败；否则碎盾并打掉 1 颗心
	for i in 2:
		if str(acts[i]) != "skill":
			continue
		var foe := 1 - i
		var s := int(spent[i])
		var fsh := int(players[foe]["shield"])
		var pcol: Color = players[i]["accent"]
		_chibis[i].play_state("skill", 0.55)
		if s > fsh:
			instant[i] = true
			_chibis[foe].play_state("hurt", 1.0)
			_skill_effect(pcol, "破 防！", foe)
			_audio.play("skill")
		else:
			players[foe]["shield"] = 0
			dmg[foe] += 1
			_chibis[foe].play_state("hurt", 0.7)
			_skill_effect(pcol, "盾碎！", foe)
			_audio.play("hit")
	await get_tree().create_timer(0.5).timeout

	# 3) 普攻：对手还有护盾就挡下，否则掉 1 心并震散 1 气
	for i in 2:
		if str(acts[i]) != "attack":
			continue
		var foe := 1 - i
		_lunge(i)
		if int(players[foe]["shield"]) > 0:
			players[foe]["shield"] = int(players[foe]["shield"]) - 1
			_chibis[foe].play_state("hurt", 0.42)
			_float_on(foe, "挡住啦！", C_DEFEND, 20)
			_audio.play("guard")
		else:
			dmg[foe] += 1
			_chibis[foe].play_state("hurt", 0.55)
			_shake(_chibis[foe])
			_float_on(foe, "-1 ♥", C_HEART, 30)
			_audio.play("hit")
			if int(players[foe]["qi"]) > 0:
				players[foe]["qi"] = int(players[foe]["qi"]) - 1
				_float_on(foe, "-1 气", C_CHARGE, 18, 40.0)

	# 4) 伤害同时落地（可能同归于尽）
	for i in 2:
		if int(dmg[i]) > 0:
			players[i]["hp"] = maxi(0, int(players[i]["hp"]) - int(dmg[i]))
	for i in 2:
		if instant[i]:
			players[1 - i]["hp"] = 0
	_update_ui()
	await get_tree().create_timer(0.78).timeout

	var dead0 := int(players[0]["hp"]) <= 0
	var dead1 := int(players[1]["hp"]) <= 0
	if dead0 or dead1:
		if dead0 and dead1:
			await _finish_round(-1, "两败俱伤，谁也讨不到好！")
		elif dead1:
			await _finish_round(0, _reason_for(0, instant))
		else:
			await _finish_round(1, _reason_for(1, instant))
		return
	round_no += 1
	resolving = false
	_after_round()


## 一回合结算完（未分胜负）：单机继续热座，联机回自己的出招界面
func _after_round() -> void:
	if mode == "online":
		_online_begin_pick()
	else:
		_begin_round()


func _reason_for(winner: int, instant: Array) -> String:
	if bool(instant[winner]):
		return "气大于盾，破防成功！"
	return "%s 的气血用完了！" % str(players[1 - winner]["name"])


## 每回合开始：交替谁先选招（同时也让设备自然交接），先遮挡再选。
func _begin_round() -> void:
	pending = ["", ""]
	current = first_player if (round_no % 2 == 1) else (1 - first_player)
	phase = "handoff"
	resolving = false
	game_over = false
	_show_handoff(current)


## 全屏遮挡：让当前玩家拿设备选招，避免对手偷看
func _show_handoff(next_idx: int) -> void:
	current = next_idx
	phase = "handoff"
	_refresh_buttons()
	_update_ui()
	var accent: Color = players[next_idx]["accent"]
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(1.0, 0.97, 0.90, 0.985)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(470, 250)
	card.add_theme_stylebox_override("panel", _panel_style(accent, true))
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	margin.add_child(vb)
	var name_label := _label(str(players[next_idx]["name"]), 34, accent, _font_title)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(name_label)
	var hint := _label("请把设备交给 %s，其他人暂时回避\n选好招式前，别让对手看到哦" % str(players[next_idx]["name"]), 15, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hint)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	vb.add_child(gap)
	var go := _big_button("我 准 备 好 了", accent)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void:
		ov.queue_free()
		phase = "select"
		_update_ui()
	)
	vb.add_child(go)
	_overlay_layer.add_child(ov)
	ov.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(ov, "modulate:a", 1.0, 0.18)


func _action_name(kind: String) -> String:
	match kind:
		"attack": return "攻击"
		"defend": return "防守"
		"charge": return "聚气"
		_: return "破防"


func _finish_round(winner: int, reason: String) -> void:
	game_over = true
	resolving = true
	phase = "over"
	if winner >= 0:
		_chibis[winner].play_state("win", 0)
		_chibis[1 - winner].play_state("lose", 0)
	else:
		_chibis[0].play_state("lose", 0)
		_chibis[1].play_state("lose", 0)
	_update_ui()
	_audio.play("win")
	await get_tree().create_timer(0.7).timeout
	_show_result(winner, reason)
	resolving = false


func _reset_game(toggle_first: bool) -> void:
	if toggle_first:
		first_player = 1 - first_player
	round_no = 1
	resolving = false
	game_over = false
	pending = ["", ""]
	for i in 2:
		players[i]["hp"] = MAX_HEARTS
		players[i]["qi"] = 0
		players[i]["shield"] = 0
		_chibis[i].play_state("idle", 0)
	for c in _fx_layer.get_children() if _fx_layer != null else []:
		c.queue_free()
	for c in _overlay_layer.get_children() if _overlay_layer != null else []:
		c.queue_free()
	_begin_round()


func _restart_match() -> void:
	if mode == "online":
		_leave_online_to_menu()
		return
	if resolving and not game_over:
		return
	_reset_game(true)


# ---------------------------------------------------------------------------
# 界面刷新
# ---------------------------------------------------------------------------
func _update_ui() -> void:
	_round_label.text = "第 %d 回合" % round_no
	var selecting := phase == "select" and not game_over
	var local_idx := my_seat if mode == "online" else current
	for i in 2:
		var p: Dictionary = players[i]
		var accent: Color = p["accent"]
		_heart_rows[i].set_data(int(p["hp"]), MAX_HEARTS)
		_qi_rows[i].set_data(int(p["qi"]), MAX_QI)
		_shield_rows[i].set_data(int(p["shield"]), MAX_SHIELD)
		_active_tags[i].visible = (i == local_idx and selecting)
		_panels[i].add_theme_stylebox_override("panel", _panel_style(accent, i == local_idx and selecting))
		_chibis[i].active = i == local_idx and selecting
	if game_over:
		_refresh_buttons()
		return
	# reveal / resolve 阶段由结算流程自己写转场文案，避免被覆盖
	if mode == "online":
		if phase == "select":
			var me: Dictionary = players[my_seat]
			var mac: Color = me["accent"]
			_turn_label.text = "轮到 你 出招！（%s）" % str(me["name"])
			_turn_panel.add_theme_stylebox_override("panel", _flat(mac, Color(1, 1, 1, 0.92), 2, 23))
		elif phase == "waiting":
			var me2: Dictionary = players[my_seat]
			var mac2: Color = me2["accent"]
			_turn_label.text = "等待对手出招…"
			_turn_panel.add_theme_stylebox_override("panel", _flat(mac2, Color(1, 1, 1, 0.92), 2, 23))
	elif phase == "select" or phase == "handoff":
		var p: Dictionary = players[current]
		var accent: Color = p["accent"]
		if phase == "select":
			_turn_label.text = "轮到 %s 出招！" % str(p["name"])
		else:
			_turn_label.text = "等待 %s 出招…" % str(p["name"])
		_turn_panel.add_theme_stylebox_override("panel", _flat(accent, Color(1, 1, 1, 0.92), 2, 23))
	_refresh_buttons()


func _refresh_buttons() -> void:
	if _cards.is_empty():
		return
	var cp: Dictionary = players[current]
	var can_skill := int(cp["qi"]) >= SKILL_COST
	for kind in _cards.keys():
		var c: Dictionary = _cards[kind]
		var b: Button = c["button"]
		var enabled := phase == "select" and not game_over
		if kind == "skill":
			enabled = enabled and can_skill
		b.disabled = not enabled
		var alpha := 1.0 if enabled else 0.48
		for key in ["title", "desc", "icon"]:
			var node: Control = c[key]
			node.modulate = Color(1, 1, 1, alpha)
		var cost_label: Label = c["cost"]
		if kind == "skill":
			cost_label.text = "可以发动！" if can_skill else "需 3 气"
			cost_label.add_theme_color_override("font_color", C_SKILL if can_skill else Color("#b7aaa2"))
		cost_label.modulate = Color(1, 1, 1, alpha)


# ---------------------------------------------------------------------------
# 动画与特效
# ---------------------------------------------------------------------------
func _lunge(idx: int) -> void:
	var c := _chibis[idx]
	var home := c.position
	var dx := 34.0 if idx == 0 else -34.0
	var tw := create_tween()
	tw.tween_property(c, "position", home + Vector2(dx, 0.0), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position", home, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _bounce(c: Control) -> void:
	c.pivot_offset = c.size * 0.5
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector2(1.07, 0.94), 0.07)
	tw.tween_property(c, "scale", Vector2(0.97, 1.04), 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.10)


func _shake(c: Control) -> void:
	c.pivot_offset = c.size * 0.5
	var tw := create_tween()
	tw.tween_property(c, "rotation", deg_to_rad(-4.0), 0.05)
	tw.tween_property(c, "rotation", deg_to_rad(4.0), 0.07)
	tw.tween_property(c, "rotation", 0.0, 0.08)


func _float_on(idx: int, text: String, color: Color, font_size: int, y_offset: float = 0.0) -> void:
	var gp := _chibis[idx].get_global_rect().get_center()
	var l := _label(text, font_size, color, _font_title if font_size >= 24 else _font_body)
	l.size = Vector2(300, 44)
	l.position = Vector2(gp.x - 150.0, gp.y - 80.0 + y_offset)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.z_index = 20
	_fx_layer.add_child(l)
	l.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "modulate:a", 1.0, 0.10)
	tw.tween_property(l, "position:y", l.position.y - 52.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.28).set_delay(0.52)
	tw.set_parallel(false)
	tw.tween_callback(l.queue_free)


func _skill_effect(color: Color, text: String, target: int) -> void:
	var flash := ColorRect.new()
	flash.color = Color(color.r, color.g, color.b, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_layer.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.55, 0.08)
	tw.tween_property(flash, "color:a", 0.0, 0.30)
	tw.tween_callback(flash.queue_free)
	var burst := _label(text, 74, color, _font_title)
	burst.size = Vector2(600, 130)
	burst.position = Vector2(340, 255)
	burst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.95))
	burst.add_theme_constant_override("outline_size", 10)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.pivot_offset = Vector2(300, 65)
	burst.scale = Vector2(0.55, 0.55)
	burst.z_index = 30
	_fx_layer.add_child(burst)
	var tw2 := create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(burst, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.tween_property(burst, "modulate:a", 0.0, 0.35).set_delay(0.52)
	_shake(_chibis[target])


func _action_log(text: String) -> void:
	# 战报很短，只在屏幕顶部显示一小条，不抢画面。
	pass


# ---------------------------------------------------------------------------
# 胜利界面
# ---------------------------------------------------------------------------
func _show_result(winner: int, reason: String) -> void:
	var draw := winner < 0
	var accent: Color = C_GOLD
	if not draw:
		accent = players[winner]["accent"]
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(1.0, 0.96, 0.84, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dim)
	var confetti := Confetti.new()
	confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(confetti)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 400)
	card.add_theme_stylebox_override("panel", _panel_style(accent, true))
	center.add_child(card)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)
	var star := _label("★", 62, C_GOLD, _font_title)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(star)
	var title := _label("平 局 ！" if draw else "%s 赢啦！" % str(players[winner]["name"]), 42, accent, _font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	title.add_theme_constant_override("outline_size", 8)
	vb.add_child(title)
	var why := _label(reason, 16, C_MUTED)
	why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(why)
	var stat_text := "小玄 ♥ %d  气 %d  盾 %d      小赤 ♥ %d  气 %d  盾 %d" % [
		int(players[0]["hp"]), int(players[0]["qi"]), int(players[0]["shield"]),
		int(players[1]["hp"]), int(players[1]["qi"]), int(players[1]["shield"])
	] if draw else "♥ %d    气 %d    盾 %d" % [int(players[winner]["hp"]), int(players[winner]["qi"]), int(players[winner]["shield"])]
	var stats := _label(stat_text, 15, C_TEXT)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stats)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	vb.add_child(gap)
	if mode == "online":
		_result_status = _label("", 13, C_MUTED)
		_result_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(_result_status)
	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 12)
	if mode == "online":
		_result_rematch_btn = _big_button("再 来 一 局", C_GOLD)
		_result_rematch_btn.pressed.connect(_request_rematch)
		btns.add_child(_result_rematch_btn)
		var lobby := _big_button("返 回 大 厅", Color("#b8c3cc"))
		lobby.pressed.connect(_leave_online_to_menu)
		btns.add_child(lobby)
	else:
		var again := _big_button("再 来 一 局", C_GOLD)
		again.pressed.connect(func() -> void:
			_reset_game(true)
		)
		btns.add_child(again)
		var quit := _big_button("退 出", Color("#b8c3cc"))
		quit.pressed.connect(func() -> void: get_tree().quit())
		btns.add_child(quit)
	vb.add_child(btns)
	_overlay_layer.add_child(ov)
	ov.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(ov, "modulate:a", 1.0, 0.22)
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.86, 0.86)
	var tw2 := create_tween()
	tw2.tween_property(card, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# 输入
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if phase == "menu":
			return
		if event.keycode == KEY_R:
			_restart_match()
			return
		if game_over:
			return
		match event.keycode:
			KEY_1: _request_action("attack")
			KEY_2: _request_action("defend")
			KEY_3: _request_action("charge")
			KEY_4: _request_action("skill")


# ---------------------------------------------------------------------------
# 小工具
# ---------------------------------------------------------------------------
func _label(text: String, font_size: int, color: Color, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	if font != null:
		l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _flat(bg: Color, border: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	return sb


func _panel_style(accent: Color, active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.88)
	sb.border_color = Color(accent.r, accent.g, accent.b, 0.80) if active else Color("#eadfce")
	sb.set_border_width_all(3 if active else 2)
	sb.set_corner_radius_all(22)
	sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.14 if active else 0.07)
	sb.shadow_size = 16 if active else 8
	sb.shadow_offset = Vector2(0, 4)
	return sb


func _card_style(accent: Color, state: String) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(18)
	match state:
		"normal":
			sb.bg_color = Color(1, 1, 1, 0.92)
			sb.border_color = Color(accent.r, accent.g, accent.b, 0.55)
			sb.set_border_width_all(2)
			sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.08)
			sb.shadow_size = 5
		"hover":
			sb.bg_color = Color(accent.r, accent.g, accent.b, 0.10)
			sb.border_color = Color(accent.r, accent.g, accent.b, 0.85)
			sb.set_border_width_all(3)
			sb.shadow_color = Color(accent.r, accent.g, accent.b, 0.16)
			sb.shadow_size = 10
		"pressed":
			sb.bg_color = Color(accent.r, accent.g, accent.b, 0.20)
			sb.border_color = Color(accent.r, accent.g, accent.b, 0.75)
			sb.set_border_width_all(3)
		"disabled":
			sb.bg_color = Color(0.95, 0.93, 0.89, 0.75)
			sb.border_color = Color("#ddd2c4")
			sb.set_border_width_all(2)
	return sb


func _small_button(text: String, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", _font_title)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", accent.darkened(0.10))
	b.add_theme_stylebox_override("normal", _flat(Color(1, 1, 1, 0.68), Color(accent.r, accent.g, accent.b, 0.30), 1, 12))
	b.add_theme_stylebox_override("hover", _flat(Color(accent.r, accent.g, accent.b, 0.10), Color(accent.r, accent.g, accent.b, 0.50), 2, 12))
	b.add_theme_stylebox_override("pressed", _flat(Color(accent.r, accent.g, accent.b, 0.16), Color(accent.r, accent.g, accent.b, 0.40), 2, 12))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b


func _big_button(text: String, accent: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(180, 52)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", _font_title)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("#5d4a43"))
	b.add_theme_color_override("font_hover_color", Color("#4b3932"))
	b.add_theme_stylebox_override("normal", _flat(accent, Color(1, 1, 1, 0.9), 3, 17))
	b.add_theme_stylebox_override("hover", _flat(accent.lightened(0.14), Color.WHITE, 3, 17))
	b.add_theme_stylebox_override("pressed", _flat(accent.darkened(0.08), Color.WHITE, 3, 17))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b

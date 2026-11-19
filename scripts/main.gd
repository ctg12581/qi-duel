extends Control
## 气破 · Q版 双人同屏回合制小游戏
## 血/攻/防/气四维数值：聚气蓄力，把气分配给攻击或防御，普攻见血。

const MAX_HP := 10
const MAX_ATK := 5
const MAX_DEF := 3
const MAX_QI := 5
const BASE_ATK := 1
const BASE_DEF := 1
const BASE_QI := 1
## 「防御」动作在本回合额外提供的防御值
const DEFEND_BONUS := 2

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
const DEFAULT_SERVER := "wss://qi-duel-server.onrender.com"
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
	var char_id := ""
	var state := "idle"
	var active := false
	var _t := 0.0
	var _tex: Texture2D = null
	var _cache: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
		_tex = _pose_texture("idle")

	func set_character(id: String) -> void:
		char_id = id
		_cache.clear()
		_tex = _pose_texture("idle")
		queue_redraw()

	func _pose_texture(pose: String) -> Texture2D:
		var key := char_id + "|" + pose
		if _cache.has(key):
			return _cache[key]
		var path := "res://assets/characters/%s_%s.png" % [char_id, pose]
		if not ResourceLoader.exists(path):
			path = "res://assets/characters/%s_idle.png" % char_id
		var tex: Texture2D = null
		if ResourceLoader.exists(path):
			tex = load(path)
		_cache[key] = tex
		return tex

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func play_state(s: String, dur: float = 0.45) -> void:
		state = s
		_tex = _pose_texture(s)
		queue_redraw()
		if dur > 0.0:
			var tw := create_tween()
			tw.tween_interval(dur)
			tw.tween_callback(func() -> void:
				if state == s:
					state = "idle"
					_tex = _pose_texture("idle")
					queue_redraw()
			)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w < 20.0 or h < 20.0:
			return
		var cx := w * 0.5
		var ground := h * 0.93
		var bob := 0.0
		if state == "idle" or state == "guard" or state == "charge":
			bob = sin(_t * 2.4 + float(index) * 1.7) * 3.0
		if active:
			for i in range(5, 0, -1):
				draw_circle(Vector2(cx, ground - 6.0), 54.0 + float(i) * 9.0, Color(accent.r, accent.g, accent.b, 0.016))
			draw_arc(Vector2(cx, ground - 6.0), 68.0, 0.0, TAU, 48, Color(accent.r, accent.g, accent.b, 0.38), 2.0, true)
		# 地面投影
		_ellipse(Vector2(cx, ground), Vector2(56.0, 14.0), Color(0.18, 0.30, 0.18, 0.18))
		if _tex == null:
			return
		# 宽高双约束等比缩放，底部对齐地面
		var tw_ := float(_tex.get_width())
		var th_ := float(_tex.get_height())
		if tw_ <= 0.0 or th_ <= 0.0:
			return
		var max_w := w * 0.96
		var max_h := h * 0.90
		var sc := minf(max_w / tw_, max_h / th_)
		var draw_w := tw_ * sc
		var draw_h := th_ * sc
		var pos := Vector2(cx - draw_w * 0.5, ground - draw_h + bob)
		var mod := Color(1, 1, 1, 1)
		if state == "hurt":
			mod = Color(1.0, 0.68, 0.68, 1.0)
		draw_texture_rect(_tex, Rect2(pos, Vector2(draw_w, draw_h)), false, mod)

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
		var fit := spacing * 0.44
		for i in max_value:
			var c := Vector2(spacing * 0.5 + float(i) * spacing, cy)
			var filled := i < value
			if kind == "heart":
				_heart(c, minf(9.5, fit), filled)
			elif kind == "qi":
				_orb(c, minf(8.5, fit * 0.95), filled)
			elif kind == "blade":
				_blade(c, minf(8.5, fit * 0.95), filled)
			else:
				_shield(c, minf(9.0, fit), filled)

	func _blade(c: Vector2, s: float, filled: bool) -> void:
		var pts := PackedVector2Array([
			c + Vector2(0, -s),
			c + Vector2(s * 0.78, s * 0.85),
			c + Vector2(0, s * 0.45),
			c + Vector2(-s * 0.78, s * 0.85),
		])
		if filled:
			draw_colored_polygon(pts, accent)
		else:
			draw_colored_polygon(pts, Color(1, 1, 1, 0.55))
			pts.append(pts[0])
			draw_polyline(pts, Color(accent.r, accent.g, accent.b, 0.35), 1.5, true)

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
	{"name": "Doro", "hp": MAX_HP, "atk": BASE_ATK, "def": BASE_DEF, "qi": BASE_QI, "accent": C_P1},
	{"name": "鲸鱼娘", "hp": MAX_HP, "atk": BASE_ATK, "def": BASE_DEF, "qi": BASE_QI, "accent": C_P2},
]

## 可选角色花名册（贴图：res://assets/characters/<id>_<状态>.png）
var ROSTER: Array[Dictionary] = [
	{"id": "doro", "name": "Doro", "desc": "粉毛呆萌小狗", "accent": Color("#ff9ec4")},
	{"id": "guga", "name": "咕嘎", "desc": "企鹅装小可爱", "accent": Color("#6b7280")},
	{"id": "whale", "name": "鲸鱼娘", "desc": "蓝发女仆大肥鱼", "accent": Color("#5b8cff")},
]
## 每个座位当前选中的角色 id（1P 默认 Doro，2P 默认鲸鱼娘）
var picked: Array[String] = ["doro", "whale"]

var current := 0
var first_player := 0
var round_no := 1
var resolving := false
var game_over := false
## select: 当前玩家选招 / handoff: 交接遮挡 / reveal: 亮招 / resolve: 结算 / over: 结束
var phase := "select"
## 本回合双方各自选定的招式，空串表示还没选
var pending: Array[String] = ["", ""]
## 本回合双方各自把多少「气」分配到攻击 / 防御（结算时一次性落实为永久加成）
var turn_alloc: Array[Dictionary] = [{"atk": 0, "def": 0}, {"atk": 0, "def": 0}]

## hotseat：单机同屏；online：联网对战
var mode := "hotseat"
## 联机时本客户端控制哪一方（0=玩家1，1=玩家2）
var my_seat := 0
var _net
var _pending_net_cmd: Dictionary = {}
var _my_rematch := false
var _opp_rematch := false
var _result_status: Label
var _result_rematch_btn: Button
var _top_btn: Button
var _lobby_status: Label
var _lobby_rooms_box: VBoxContainer
var _lobby_room_codes: Array[String] = []

var _font_body: Font
var _font_title: Font
var _audio: CuteAudio

var _panels: Array[PanelContainer] = []
var _active_tags: Array[Label] = []
var _name_labels: Array[Label] = []
var _pick_buttons: Array = []
var _hp_rows: Array[PipRow] = []
var _atk_rows: Array[PipRow] = []
var _def_rows: Array[PipRow] = []
var _qi_rows: Array[PipRow] = []
var _stat_vals: Array[Dictionary] = []
var _chibis: Array[Chibi] = []
var _cards: Dictionary = {}
var _alloc_atk_btn: Button
var _alloc_def_btn: Button
var _alloc_info: Label

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
	_name_labels.resize(2)
	_hp_rows.resize(2)
	_atk_rows.resize(2)
	_def_rows.resize(2)
	_qi_rows.resize(2)
	_stat_vals.resize(2)
	for i in 2:
		_stat_vals[i] = {}
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
	# 网页导出无法读取系统字体（SystemFont 在 Web 上会退回默认拉丁字体，
	# 中文就会变成方框/乱码），因此这里优先使用项目内置的中文字体，
	# 只有在字体文件缺失时才退回 SystemFont（桌面端兜底）。
	var body: Font = load("res://fonts/NotoSansSC-Medium.ttf")
	if body == null:
		var fb := SystemFont.new()
		fb.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "SimHei", "Noto Sans CJK SC"])
		fb.font_weight = 500
		body = fb
	_font_body = body
	var title: Font = load("res://fonts/NotoSansSC-Bold.ttf")
	if title == null:
		var ft := SystemFont.new()
		ft.font_names = PackedStringArray(["YouYuan", "Microsoft YaHei UI", "Microsoft YaHei", "SimHei"])
		ft.font_weight = 700
		title = ft
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

	var sub := _label("各自选招 · 一起结算 · 聚 气 化 攻 防", 14, Color("#8a746a"))
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
	_name_labels[idx] = name_label
	var seat_tag := _label("玩家%d" % (idx + 1), 11, C_MUTED)
	seat_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(seat_tag)
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
	vb.add_child(_stat_row("气血", "heart", C_HEART, idx, "hp", _hp_rows, _stat_vals))
	vb.add_child(_stat_row("攻击", "blade", C_ATTACK, idx, "atk", _atk_rows, _stat_vals))
	vb.add_child(_stat_row("防御", "shield", C_DEFEND, idx, "def", _def_rows, _stat_vals))
	vb.add_child(_stat_row("气", "qi", C_CHARGE, idx, "qi", _qi_rows, _stat_vals))


func _stat_row(caption: String, kind: String, color: Color, idx: int, key: String, pips_store: Array, val_store: Array) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l := _label(caption, 12, C_MUTED)
	l.custom_minimum_size = Vector2(32, 20)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var pips := PipRow.new()
	pips.kind = kind
	pips.accent = color
	pips.custom_minimum_size = Vector2(0, 20)
	pips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(pips)
	pips_store[idx] = pips
	var v := _label("0/0", 12, C_TEXT)
	v.custom_minimum_size = Vector2(46, 20)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(v)
	val_store[idx][key] = v
	return h


func _build_arena() -> void:
	var p1 := Chibi.new()
	p1.position = Vector2(310, 145)
	p1.size = Vector2(240, 300)
	p1.index = 0
	p1.accent = C_P1
	p1.char_id = picked[0]
	add_child(p1)
	_chibis[0] = p1
	var p2 := Chibi.new()
	p2.position = Vector2(730, 145)
	p2.size = Vector2(240, 300)
	p2.index = 1
	p2.accent = C_P2
	p2.char_id = picked[1]
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
	_turn_label = _label("准 备 出 招", 21, Color.WHITE, _font_title)
	_turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tm.add_child(_turn_label)


func _build_dock() -> void:
	var dock := PanelContainer.new()
	dock.position = Vector2(70, 506)
	dock.size = Vector2(1140, 200)
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
	var hint := _label("鼠标点击  ·  键盘 1 / 2 / 3 出招，Q / E 加攻防", 12, C_MUTED)
	head.add_child(hint)
	vb.add_child(head)
	# 气分配栏：把气换成永久攻击 / 防御加成
	var alloc_row := HBoxContainer.new()
	alloc_row.add_theme_constant_override("separation", 8)
	var al := _label("分 配 气 ：", 13, C_MUTED)
	al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alloc_row.add_child(al)
	_alloc_info = _label("", 13, C_CHARGE)
	_alloc_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alloc_row.add_child(_alloc_info)
	var sp2 := Control.new()
	sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alloc_row.add_child(sp2)
	_alloc_atk_btn = _small_button("气 → 攻 +1", C_ATTACK)
	_alloc_atk_btn.pressed.connect(func() -> void: _allocate("atk"))
	alloc_row.add_child(_alloc_atk_btn)
	_alloc_def_btn = _small_button("气 → 防 +1", C_DEFEND)
	_alloc_def_btn.pressed.connect(func() -> void: _allocate("def"))
	alloc_row.add_child(_alloc_def_btn)
	vb.add_child(alloc_row)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	_add_card(row, "attack", "攻", "普通攻击", "伤害 = 攻击 − 对方防御\n最低 0", "无消耗", C_ATTACK, "1")
	_add_card(row, "defend", "防", "防御姿态", "本回合 防御 +%d\n挡下普攻" % DEFEND_BONUS, "无消耗", C_DEFEND, "2")
	_add_card(row, "charge", "聚", "聚气蓄力", "气 +1\n最多 5 点", "无消耗", C_CHARGE, "3")


func _add_card(row: HBoxContainer, kind: String, glyph: String, title: String, desc: String, cost: String, accent: Color, key: String) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 94)
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
	_lobby_rooms_box = null
	_lobby_status = null
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
		_show_char_select("hotseat")
	)
	vb.add_child(hot)
	var online := _big_button("联 网 对 战", C_P2)
	online.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	online.pressed.connect(_show_online_lobby)
	vb.add_child(online)
	_overlay_layer.add_child(ov)
	_fade_in(ov)


func _roster_entry(id: String) -> Dictionary:
	for r in ROSTER:
		if str(r["id"]) == id:
			return r
	return ROSTER[0]


func _char_thumb(id: String) -> Texture2D:
	var path := "res://assets/characters/%s_idle.png" % id
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _apply_characters() -> void:
	for i in 2:
		var ch := _roster_entry(picked[i])
		players[i]["name"] = str(ch["name"])
		if i < _name_labels.size() and _name_labels[i] != null:
			_name_labels[i].text = str(ch["name"])
		if i < _chibis.size() and _chibis[i] != null:
			_chibis[i].set_character(picked[i])
	_update_ui()


func _on_pick(seat: int, rid: String) -> void:
	picked[seat] = rid
	_refresh_pick_ui()


func _refresh_pick_ui() -> void:
	for e in _pick_buttons:
		var on := str(e["rid"]) == picked[int(e["seat"])]
		var b: Button = e["button"]
		var acc: Color = _roster_entry(str(e["rid"]))["accent"]
		b.add_theme_stylebox_override("normal", _card_style(acc, "hover" if on else "normal"))
		b.add_theme_stylebox_override("hover", _card_style(acc, "hover"))
		b.modulate = Color(1, 1, 1, 1) if on else Color(1, 1, 1, 0.62)


func _show_char_select(next_mode: String) -> void:
	_clear_overlay()
	phase = "menu"
	game_over = false
	_update_ui()
	_pick_buttons.clear()
	var ov := _overlay_base(Color(1.0, 0.97, 0.90, 0.96))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(840, 470)
	card.add_theme_stylebox_override("panel", _panel_style(C_GOLD, true))
	center.add_child(card)
	var margin := _pad(card, 28, 28, 22, 22)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	margin.add_child(vb)
	var title := _label("选 择 你 的 角 色", 32, Color("#6b4b8a"), _font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var sub := _label("两 位 玩 家 各 挑 一 个 萌 形 象", 14, C_MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sub)
	for seat in 2:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var sl := _label("玩家%d" % (seat + 1), 18, (C_P1 if seat == 0 else C_P2), _font_title)
		sl.custom_minimum_size = Vector2(66, 0)
		sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(sl)
		for r in ROSTER:
			var bid := str(r["id"])
			var b := Button.new()
			b.custom_minimum_size = Vector2(0, 100)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.focus_mode = Control.FOCUS_NONE
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.pressed.connect(_on_pick.bind(seat, bid))
			var h := HBoxContainer.new()
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_theme_constant_override("separation", 8)
			var thumb := TextureRect.new()
			thumb.texture = _char_thumb(bid)
			thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			thumb.custom_minimum_size = Vector2(68, 68)
			thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(thumb)
			var tv := VBoxContainer.new()
			tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tv.alignment = BoxContainer.ALIGNMENT_CENTER
			var nm := _label(str(r["name"]), 18, C_TEXT, _font_title)
			nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tv.add_child(nm)
			var ds := _label(str(r["desc"]), 11, C_MUTED)
			ds.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tv.add_child(ds)
			h.add_child(tv)
			b.add_child(h)
			row.add_child(b)
			_pick_buttons.append({"seat": seat, "rid": bid, "button": b})
		vb.add_child(row)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	vb.add_child(gap)
	var go := _big_button("开 始 对 战", C_GOLD)
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void:
		_clear_overlay()
		_apply_characters()
		if next_mode == "hotseat":
			_start_hotseat()
		else:
			_show_online_lobby()
	)
	vb.add_child(go)
	var back := _small_button("返 回", Color("#8a746a"))
	back.pressed.connect(_show_mode_menu)
	vb.add_child(back)
	_overlay_layer.add_child(ov)
	_refresh_pick_ui()
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
	card.custom_minimum_size = Vector2(560, 480)
	card.add_theme_stylebox_override("panel", _panel_style(C_P2, true))
	center.add_child(card)
	var margin := _pad(card, 28, 28, 20, 20)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 9)
	margin.add_child(vb)
	var title := _label("联 网 对 战", 32, C_P2, _font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var hint := _label("点「创建房间」开个房间等朋友；\n或者直接在下面的房间列表里点一下加入～", 13, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hint)

	_lobby_status = _label("连接服务器中…", 13, Color("#8a746a"))
	_lobby_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_lobby_status)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 216)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	_lobby_rooms_box = VBoxContainer.new()
	_lobby_rooms_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lobby_rooms_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_lobby_rooms_box)
	_render_room_list([])

	var btns := HBoxContainer.new()
	btns.alignment = BoxContainer.ALIGNMENT_CENTER
	btns.add_theme_constant_override("separation", 12)
	vb.add_child(btns)
	var create_btn := _big_button("创 建 房 间", C_P1)
	create_btn.pressed.connect(_online_create)
	btns.add_child(create_btn)
	var refresh_btn := _big_button("刷 新", Color("#b8c3cc"))
	refresh_btn.pressed.connect(_lobby_refresh)
	btns.add_child(refresh_btn)

	var back := _small_button("返 回", Color("#8a746a"))
	back.pressed.connect(_leave_online_to_menu)
	vb.add_child(back)
	_overlay_layer.add_child(ov)
	_fade_in(ov)
	_lobby_connect()


## 保证已经连上服务器并请求房间列表
func _lobby_connect() -> void:
	if _lobby_status != null and is_instance_valid(_lobby_status):
		_lobby_status.text = "连接服务器中…"
	_pending_net_cmd = {"t": "list"}
	if _net.is_open():
		_net.send_json({"t": "list"})
		_pending_net_cmd = {}
	else:
		_net.connect_to(DEFAULT_SERVER)


func _lobby_refresh() -> void:
	if _net.is_open():
		if _lobby_status != null and is_instance_valid(_lobby_status):
			_lobby_status.text = "刷新中…"
		_net.send_json({"t": "list"})
	else:
		_lobby_connect()


## 渲染大厅房间列表；每个房间一行，点一下直接加入
func _render_room_list(room_infos: Array) -> void:
	if _lobby_rooms_box == null or not is_instance_valid(_lobby_rooms_box):
		return
	_lobby_room_codes.clear()
	for c in _lobby_rooms_box.get_children():
		_lobby_rooms_box.remove_child(c)
		c.queue_free()
	if room_infos.is_empty():
		var empty := _label("暂时没有房间，点「创建房间」开一个吧～", 13, Color("#a89890"))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.custom_minimum_size = Vector2(0, 70)
		_lobby_rooms_box.add_child(empty)
		return
	for i in room_infos.size():
		var info: Dictionary = room_infos[i]
		var code := str(info.get("code", ""))
		var players_n := int(info.get("players", 1))
		var cap := int(info.get("capacity", 2))
		_lobby_room_codes.append(code)
		var row := Button.new()
		row.text = "房间 %d          %d/%d 人                  加入 ›" % [i + 1, players_n, cap]
		row.custom_minimum_size = Vector2(0, 54)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.focus_mode = Control.FOCUS_NONE
		row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row.add_theme_font_override("font", _font_title)
		row.add_theme_font_size_override("font_size", 16)
		row.add_theme_color_override("font_color", C_TEXT)
		row.add_theme_color_override("font_hover_color", C_TEXT)
		row.add_theme_stylebox_override("normal", _card_style(C_P1, "normal"))
		row.add_theme_stylebox_override("hover", _card_style(C_P1, "hover"))
		row.add_theme_stylebox_override("pressed", _card_style(C_P1, "pressed"))
		row.pressed.connect(_online_join_code.bind(code))
		_lobby_rooms_box.add_child(row)


## 建房成功后的等待界面（不显示房间码，只等对手从列表加入）
func _show_waiting_room() -> void:
	_clear_overlay()
	_lobby_rooms_box = null
	_lobby_status = null
	mode = "online"
	phase = "menu"
	var ov := _overlay_base(Color(1.0, 0.97, 0.90, 0.96))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(470, 260)
	card.add_theme_stylebox_override("panel", _panel_style(C_P1, true))
	center.add_child(card)
	var margin := _pad(card, 30, 30, 24, 24)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 12)
	margin.add_child(vb)
	var title := _label("房 间 已 创 建", 26, C_P1, _font_title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var hint := _label("等待对手加入…\n对手在大厅的房间列表里点进来就能开局～", 14, C_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(hint)
	var cancel := _small_button("取 消 并 返 回", Color("#8a746a"))
	cancel.pressed.connect(_cancel_waiting_room)
	vb.add_child(cancel)
	_overlay_layer.add_child(ov)
	_fade_in(ov)


func _cancel_waiting_room() -> void:
	if _net.is_open():
		_net.send_json({"t": "leave"})
	_show_online_lobby()


func _online_create() -> void:
	if _lobby_status != null and is_instance_valid(_lobby_status):
		_lobby_status.text = "正在创建房间…"
	_pending_net_cmd = {"t": "create"}
	if _net.is_open():
		_net.send_json({"t": "create"})
		_pending_net_cmd = {}
	else:
		_net.connect_to(DEFAULT_SERVER)


func _online_join_code(code: String) -> void:
	if code == "":
		return
	if _lobby_status != null and is_instance_valid(_lobby_status):
		_lobby_status.text = "正在加入房间…"
	_pending_net_cmd = {"t": "join", "room": code}
	if _net.is_open():
		_net.send_json({"t": "join", "room": code})
		_pending_net_cmd = {}
	else:
		_net.connect_to(DEFAULT_SERVER)


func _on_net_connected() -> void:
	if not _pending_net_cmd.is_empty():
		_net.send_json(_pending_net_cmd)
		_pending_net_cmd = {}
	elif _lobby_rooms_box != null and is_instance_valid(_lobby_rooms_box):
		_net.send_json({"t": "list"})


func _on_net_disconnected() -> void:
	if mode == "online" and phase == "menu" and _lobby_rooms_box != null and is_instance_valid(_lobby_rooms_box):
		if _lobby_status != null and is_instance_valid(_lobby_status):
			_lobby_status.text = "连接断开，点「刷新」重连"
		_render_room_list([])
		return
	if mode == "online" and phase == "menu":
		_show_notice("与服务器断开连接", "返回大厅", _leave_online_to_menu)
		return
	if mode == "online" and phase != "menu" and not game_over:
		_online_peer_left()


func _on_net_message(d: Dictionary) -> void:
	var t := str(d.get("t", ""))
	match t:
		"rooms":
			if _lobby_rooms_box != null and is_instance_valid(_lobby_rooms_box):
				var room_infos: Array = d.get("rooms", [])
				_render_room_list(room_infos)
				if _lobby_status != null and is_instance_valid(_lobby_status):
					if room_infos.is_empty():
						_lobby_status.text = "暂时没有房间，点「创建房间」开一个吧～"
					else:
						_lobby_status.text = "在线房间 %d 个，点一下直接加入" % room_infos.size()
		"created":
			_show_waiting_room()
		"start":
			_start_online_match(int(d.get("seat", 0)))
		"action":
			if not game_over:
				var opp := 1 - my_seat
				pending[opp] = str(d.get("action", ""))
				var oa: Dictionary = turn_alloc[opp]
				oa["atk"] = int(d.get("atk_add", 0))
				oa["def"] = int(d.get("def_add", 0))
				if phase == "select" or phase == "waiting":
					if str(pending[my_seat]) != "":
						_start_resolve()
					else:
						_update_ui()
				# reveal / resolve 期间提前到达的招式与分配先留在 pending / turn_alloc，下一回合再用
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
	_lobby_rooms_box = null
	_lobby_status = null
	my_seat = seat
	picked[0] = "doro"
	picked[1] = "whale"
	_apply_characters()
	round_no = 1
	resolving = false
	game_over = false
	_my_rematch = false
	_opp_rematch = false
	_result_status = null
	_result_rematch_btn = null
	pending = ["", ""]
	for i in 2:
		players[i]["hp"] = MAX_HP
		players[i]["atk"] = BASE_ATK
		players[i]["def"] = BASE_DEF
		players[i]["qi"] = BASE_QI
		_chibis[i].play_state("idle", 0)
	turn_alloc = [{"atk": 0, "def": 0}, {"atk": 0, "def": 0}]
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
	_show_notice("对手已离开或掉线", "返回大厅", _back_to_online_lobby)


func _leave_online_to_menu() -> void:
	if _net != null:
		_net.close()
	_show_mode_menu()


## 离开当前房间，回到大厅房间列表（保持连接，直接刷新列表）
func _back_to_online_lobby() -> void:
	if _net != null and _net.is_open():
		_net.send_json({"t": "leave"})
	_show_online_lobby()


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
	# 联机：只控制自己这一方，选完把招式（含本回合气分配）发给服务器，等对手一起结算
	if mode == "online":
		_audio.play("click")
		pending[my_seat] = kind
		var a: Dictionary = turn_alloc[my_seat]
		_net.send_json({"t": "action", "action": kind, "atk_add": int(a["atk"]), "def_add": int(a["def"])})
		if str(pending[0]) != "" and str(pending[1]) != "":
			_start_resolve()
		else:
			phase = "waiting"
			_update_ui()
		return
	# 单机同屏
	_audio.play("click")
	pending[current] = kind
	if str(pending[0]) == "" or str(pending[1]) == "":
		# 一方已出招，遮住屏幕把设备交给另一方
		_show_handoff(1 - current)
	else:
		_start_resolve()


## 把 1 点气分配给攻击或防御（结算时一次性落实为永久加成）
func _allocate(stat: String) -> void:
	if game_over or phase != "select":
		return
	var seat := my_seat if mode == "online" else current
	var p: Dictionary = players[seat]
	var a: Dictionary = turn_alloc[seat]
	var avail := int(p["qi"]) - (int(a["atk"]) + int(a["def"]))
	if avail <= 0:
		_audio.play("error")
		return
	if stat == "atk":
		if int(p["atk"]) + int(a["atk"]) >= MAX_ATK:
			_audio.play("error")
			return
		a["atk"] = int(a["atk"]) + 1
	else:
		if int(p["def"]) + int(a["def"]) >= MAX_DEF:
			_audio.play("error")
			return
		a["def"] = int(a["def"]) + 1
	_audio.play("click")
	_bounce(_chibis[seat])
	_update_ui()


func _start_resolve() -> void:
	# 先把本回合双方招式与气分配快照下来并清空 pending，
	# 这样结算动画期间对手提前发来的下一回合数据不会误触发第二次结算。
	var acts: Array[String] = [str(pending[0]), str(pending[1])]
	var alloc: Array = [turn_alloc[0].duplicate(), turn_alloc[1].duplicate()]
	pending = ["", ""]
	turn_alloc = [{"atk": 0, "def": 0}, {"atk": 0, "def": 0}]
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
	await _resolve_round(acts, alloc)


## 同时结算：先落实气分配，再聚气/防御，最后普攻，伤害同时落地。
func _resolve_round(acts: Array, alloc: Array) -> void:
	phase = "resolve"

	# 1) 落实本回合的气分配（永久 +攻 / +防，并扣掉对应的气）
	for i in 2:
		var a: Dictionary = alloc[i]
		var add_atk := int(a.get("atk", 0))
		var add_def := int(a.get("def", 0))
		if add_atk == 0 and add_def == 0:
			continue
		var pl: Dictionary = players[i]
		pl["atk"] = mini(MAX_ATK, int(pl["atk"]) + add_atk)
		pl["def"] = mini(MAX_DEF, int(pl["def"]) + add_def)
		pl["qi"] = maxi(0, int(pl["qi"]) - add_atk - add_def)
		if add_atk > 0:
			_float_on(i, "攻 +%d" % add_atk, C_ATTACK, 22)
		if add_def > 0:
			_float_on(i, "防 +%d" % add_def, C_DEFEND, 22)
		_audio.play("charge")
	_update_ui()
	await get_tree().create_timer(0.3).timeout

	# 2) 聚气 / 防御姿态
	for i in 2:
		var p: Dictionary = players[i]
		match str(acts[i]):
			"defend":
				_chibis[i].play_state("guard", 0.38)
				_bounce(_chibis[i])
				_float_on(i, "防 +%d" % DEFEND_BONUS, C_DEFEND, 22)
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
	_update_ui()
	await get_tree().create_timer(0.45).timeout

	# 3) 本回合有效防御（防御动作额外 +DEFEND_BONUS）
	var eff_def := [0, 0]
	for i in 2:
		eff_def[i] = int(players[i]["def"]) + (DEFEND_BONUS if str(acts[i]) == "defend" else 0)

	# 4) 普攻：伤害 = 攻 − 对方有效防御，最低 0
	var dmg := [0, 0]
	for i in 2:
		if str(acts[i]) != "attack":
			continue
		var foe := 1 - i
		_lunge(i)
		_chibis[i].play_state("attack", 0.4)
		var d := maxi(0, int(players[i]["atk"]) - int(eff_def[foe]))
		dmg[foe] += d
		if d > 0:
			_float_on(foe, "-%d" % d, C_HEART, 30)
			_audio.play("hit")
		else:
			_float_on(foe, "挡住啦！", C_DEFEND, 20)
			_audio.play("guard")

	# 5) 伤害同时落地（可能同归于尽）
	for i in 2:
		if int(dmg[i]) > 0:
			players[i]["hp"] = maxi(0, int(players[i]["hp"]) - int(dmg[i]))
			_chibis[i].play_state("hurt", 0.55)
			_shake(_chibis[i])
	_update_ui()
	await get_tree().create_timer(0.75).timeout

	var dead0 := int(players[0]["hp"]) <= 0
	var dead1 := int(players[1]["hp"]) <= 0
	if dead0 or dead1:
		if dead0 and dead1:
			await _finish_round(-1, "两败俱伤，谁也讨不到好！")
		elif dead1:
			await _finish_round(0, _reason_for(0))
		else:
			await _finish_round(1, _reason_for(1))
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


func _reason_for(winner: int) -> String:
	return "把 %s 的气血打空了！" % str(players[1 - winner]["name"])


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
		"defend": return "防御"
		"charge": return "聚气"
		_: return "？"


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
		players[i]["hp"] = MAX_HP
		players[i]["atk"] = BASE_ATK
		players[i]["def"] = BASE_DEF
		players[i]["qi"] = BASE_QI
		_chibis[i].play_state("idle", 0)
	turn_alloc = [{"atk": 0, "def": 0}, {"atk": 0, "def": 0}]
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
		# 只在“当前操作方”的面板上预览本回合已分配的气，避免提前暴露对手的加點
		var a: Dictionary = turn_alloc[i] if i == local_idx else {"atk": 0, "def": 0}
		var spent := int(a["atk"]) + int(a["def"])
		var hp := int(p["hp"])
		var atk := int(p["atk"]) + int(a["atk"])
		var dfn := int(p["def"]) + int(a["def"])
		var qi := maxi(0, int(p["qi"]) - spent)
		_hp_rows[i].set_data(hp, MAX_HP)
		_atk_rows[i].set_data(atk, MAX_ATK)
		_def_rows[i].set_data(dfn, MAX_DEF)
		_qi_rows[i].set_data(qi, MAX_QI)
		_stat_vals[i]["hp"].text = "%d/%d" % [hp, MAX_HP]
		_stat_vals[i]["atk"].text = "%d/%d" % [atk, MAX_ATK]
		_stat_vals[i]["def"].text = "%d/%d" % [dfn, MAX_DEF]
		_stat_vals[i]["qi"].text = "%d/%d" % [qi, MAX_QI]
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
	var seat := my_seat if mode == "online" else current
	var can_pick := phase == "select" and not game_over
	if not _cards.is_empty():
		for kind in _cards.keys():
			var c: Dictionary = _cards[kind]
			var b: Button = c["button"]
			b.disabled = not can_pick
			var alpha := 1.0 if can_pick else 0.48
			for key in ["title", "desc", "icon"]:
				var node: Control = c[key]
				node.modulate = Color(1, 1, 1, alpha)
			var cost_label: Label = c["cost"]
			cost_label.modulate = Color(1, 1, 1, alpha)
	# 气分配按钮
	var p: Dictionary = players[seat]
	var a: Dictionary = turn_alloc[seat]
	var avail := int(p["qi"]) - (int(a["atk"]) + int(a["def"]))
	if _alloc_info != null:
		_alloc_info.text = "剩余气 %d（可换成永久攻 / 防）" % maxi(0, avail)
	if _alloc_atk_btn != null:
		var atk_ok := can_pick and avail > 0 and int(p["atk"]) + int(a["atk"]) < MAX_ATK
		_alloc_atk_btn.disabled = not atk_ok
	if _alloc_def_btn != null:
		var def_ok := can_pick and avail > 0 and int(p["def"]) + int(a["def"]) < MAX_DEF
		_alloc_def_btn.disabled = not def_ok


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
	var stat_text := ""
	if draw:
		stat_text = "%s  血%d 攻%d 防%d 气%d        %s  血%d 攻%d 防%d 气%d" % [
			str(players[0]["name"]), int(players[0]["hp"]), int(players[0]["atk"]), int(players[0]["def"]), int(players[0]["qi"]),
			str(players[1]["name"]), int(players[1]["hp"]), int(players[1]["atk"]), int(players[1]["def"]), int(players[1]["qi"])
		]
	else:
		stat_text = "血 %d   攻 %d   防 %d   气 %d" % [
			int(players[winner]["hp"]), int(players[winner]["atk"]), int(players[winner]["def"]), int(players[winner]["qi"])
		]
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
		lobby.pressed.connect(_back_to_online_lobby)
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
			KEY_Q: _allocate("atk")
			KEY_E: _allocate("def")


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

extends Node
## 轻量 WebSocket 客户端：负责建房 / 加入 / 转发选招。
## 桌面端、Web 导出都可用（Web 下页面是 https 时服务器必须用 wss://）。

signal connected()
signal disconnected()
signal message_received(data: Dictionary)

var _ws := WebSocketPeer.new()
var _state := "idle"   # idle | connecting | open | closed


func connect_to(url: String) -> void:
	close()
	_state = "connecting"
	var err := _ws.connect_to_url(url)
	if err != OK:
		_state = "closed"
		message_received.emit({"t": "error", "msg": "无法连接服务器：%s" % url})


func send_json(data: Dictionary) -> void:
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_ws.send_text(JSON.stringify(data))


func close() -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_ws.close()
	_state = "idle"


func is_open() -> bool:
	return _ws.get_ready_state() == WebSocketPeer.STATE_OPEN


func _process(_delta: float) -> void:
	_ws.poll()
	match _ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if _state != "open":
				_state = "open"
				connected.emit()
			while _ws.get_available_packet_count() > 0:
				var txt := _ws.get_packet().get_string_from_utf8()
				var parsed: Variant = JSON.parse_string(txt)
				if parsed is Dictionary:
					message_received.emit(parsed)
		WebSocketPeer.STATE_CLOSED:
			if _state == "open" or _state == "connecting":
				_state = "closed"
				disconnected.emit()

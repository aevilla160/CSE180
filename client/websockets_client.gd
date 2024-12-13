extends Node

const Packet = preload("res://packet.gd")

signal connected
signal data
signal disconnected
signal error

var socket = WebSocketPeer.new()
var last_state = WebSocketPeer.STATE_CLOSED

var should_reconnect = true
var reconnect_delay = 5.0
var reconnect_timer = 0.0

func _ready():
	var hostname = "149.28.223.185"
	var port = 8081
	var websocket_url = "ws://%s:%d" % [hostname, port]
	
	print("Attempting connection to: ", websocket_url)
	
	var err = socket.connect_to_url(websocket_url)

	if err != OK:
		print("Unable to connect, error code: ", err)
		set_process(false)
		emit_signal("error")
		return
		
	print("Connection initiated")

func _process(delta):
	#if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED and should_reconnect:
		#reconnect_timer += delta
		#if reconnect_timer >= reconnect_delay:
			#reconnect_timer = 0.0
			#_ready()
	socket.poll()
	var state = socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count():
				var packet = socket.get_packet()
				if socket.was_string_packet():
					var text = packet.get_string_from_utf8()
					print("Received packet: ", text)
					data.emit(text)
				else:
					print("Received invalid packet type")
		WebSocketPeer.STATE_CONNECTING:
			print("Still connecting...")
		WebSocketPeer.STATE_CLOSING:
			print("Connection is closing...")
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			set_process(false)
			emit_signal("disconnected")

func send_packet(packet: Packet) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		print("Cannot send packet - socket not connected")
		return
	_send_string(packet.tostring())

func _send_string(string: String) -> void:
	var err = socket.send_text(string)
	if err != OK:
		print("Error sending string: ", err)
	else:
		print("Sent string: ", string)

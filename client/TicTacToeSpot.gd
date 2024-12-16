extends Area2D

const Packet = preload("res://packet.gd")


@export var spot_number: int = 0
var _network_client = null

func set_network_client(client):
	_network_client = client
	# Now that we have a valid network client reference, we can safely send the packet
	var p = Packet.new("TicTacToeSpotEnter", [spot_number])
	_network_client.send_packet(p)

func _ready():
	# Note: We are NOT sending the packet here anymore.
	# We wait until `set_network_client()` is called to send it.
	pass


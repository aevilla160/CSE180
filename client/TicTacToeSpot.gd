# TicTacToeSpot.gd
extends Area2D

@export var spot_number: int  # Set to 1 or 2 in editor

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.get_parent().is_player:
		var network_client = get_node("/root/Main/_network_client")
		var p = TicTacToeSpotEnterPacket.new(spot_number)
		network_client.send_packet(p)

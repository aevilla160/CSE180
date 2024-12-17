de
extends Area2D

signal game_started
const Packet = preload("res://packet.gd")
const NetworkClient = preload("res://websockets_client.gd")

@export var spot_number: int
@onready var _network_client = NetworkClient.new()
var is_occupied = false
var occupying_player = null

func _ready():
	# Set up the ColorRect
	var visual = ColorRect.new()
	visual.size = Vector2(64, 64)
	visual.position = Vector2(-32, -32)  # Center it
	visual.color = Color(0.5, 0, 0.5, 0.5)  # Purple, semi-transparent
	add_child(visual)

	# Set up collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	collision.shape = shape
	add_child(collision)

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.get_parent().is_player:
		#var network_client = get_node("/root/Main/_network_client")
		var p = Packet.new("TicTacToeSpotEnter", [spot_number])
		_network_client.send_packet(p)
		is_occupied = true
		occupying_player = body
		update_appearance()

func _on_body_exited(body):
	if body == occupying_player:
		is_occupied = false
		occupying_player = null
		update_appearance()

func update_appearance():
	var visual = get_node("ColorRect")  # Get reference to your ColorRect
	if is_occupied:
		visual.color = Color(1, 0, 0, 0.5)  # Red when occupied
	else:
		visual.color = Color(0.5, 0, 0.5, 0.5)  # Purple when empty

extends Node

# Imports
const NetworkClient = preload("res://websockets_client.gd")
const Packet = preload("res://packet.gd")
const Chatbox = preload("res://Chatbox.tscn")
const TicTacToe = preload("res://tic_tac_toe.tscn")
const Spot = preload("res://TicTacToeSpot.tscn")
const Table = preload("res://TicTacToeTable.tscn")
const ui = preload("res://UI.tscn")
const Actor = preload("res://Actor.tscn")

@onready var _network_client = NetworkClient.new()
@onready var _login_screen = get_node("Login")

var _chatbox = null
var state: Callable
var _username: String
var _actors: Dictionary = {}
var _player_actor = null
var _ui = null

#TICTACTOE---------------------
var _tic_tac_toe = null
var _spots: Dictionary = {}
var _tables: Dictionary = {}
#TICTACTOE---------------------

func _ready():
	add_child(_network_client)
	_network_client.data.connect(_handle_network_data)
	_login_screen.login.connect(_handle_login_button)
	_login_screen.register.connect(_handle_register_button)
	# state = null


func LOGIN(p):
	match p.action:
		"Ok":
			_enter_game()
		"Deny":
			var reason: String = p.payloads[0]
			OS.alert(reason)


func REGISTER(p):
	match p.action:
		"Ok":
			OS.alert("Registration successful")
		"Deny":
			var reason: String = p.payloads[0]
			OS.alert(reason)


func PLAY(p):
	match p.action:
		"ModelDelta":
			var model_data: Dictionary = p.payloads[0]
			_update_models(model_data)
		"Chat":
			var username: String = p.payloads[0]
			var message: String = p.payloads[1]
			_chatbox.add_message(username, message)
		"Disconnect":
			var actor_id: int = p.payloads[0]
			var actor = _actors[actor_id]
			_chatbox.add_message(null, actor.actor_name + " has disconnected.")
			remove_child(actor)
			_actors.erase(actor_id)
#TICTACTOE---------------------
		"TicTacToeStart":
			var player1_id = p.payloads[0]
			var player2_id = p.payloads[1]
			_start_tic_tac_toe(player1_id,player2_id)
		"TicTacToeMove":
			var row = p.payloads[0]
			var col = p.payloads[1]
			var player_id = p.payloads[2]  # Now handling the player_id
			if _tic_tac_toe:
				_tic_tac_toe.handle_network_move(row,col)

func _start_tic_tac_toe(player1_id: int, player2_id: int):
	if not _tic_tac_toe:
		_tic_tac_toe = TicTacToe.instantiate()
		add_child(_tic_tac_toe)
		_tic_tac_toe.game_start(player1_id, player2_id)

func _finish_tic_tac_toe(player1_id: int, player2_id: int):
		remove_child(_tic_tac_toe)
		_tic_tac_toe.queue_free()
		_tic_tac_toe = null
#TICTACTOE---------------------


func _handle_login_button(username: String, password: String):
	state = Callable(self, "LOGIN")
	var p: Packet = Packet.new("Login", [username, password])
	_network_client.send_packet(p)
	_username = username


func _handle_register_button(username: String, password: String, avatar_id: int):
	state = Callable(self, "REGISTER")
	var p: Packet = Packet.new("Register", [username, password, avatar_id])
	_network_client.send_packet(p)


func _update_models(model_data: Dictionary):
	"""
	Runs a function with signature 
	`_update_x(model_id: int, model_data: Dictionary)` where `x` is the name 
	of a model (e.g. `_update_actor`).
	"""
	print("Received model data: %s" % JSON.stringify(model_data))
	var model_id: int = model_data["id"]
	var func_name: String = "_update_" + model_data["model_type"].to_lower()
	var f: Callable = Callable(self, func_name)
	f.call(model_id, model_data)


func _update_actor(model_id: int, model_data: Dictionary):
	# If this is an existing actor, just update them
	if model_id in _actors:
		_actors[model_id].update(model_data)
	# If this actor doesn't exist in the game yet, create them
	else:
		var new_actor
		if not _player_actor: 
			_player_actor = Actor.instantiate().init(model_data)
			_player_actor.is_player = true
			new_actor = _player_actor
		else:
			new_actor = Actor.instantiate().init(model_data)
		_actors[model_id] = new_actor
		add_child(new_actor)

func _update_tictactoespot(model_id: int, model_data: Dictionary):
	# If this spot already exists, update it	
	if model_id in _spots:
		var spot = _spots[model_id]
		spot.is_occupied = model_data.get("is_occupied", false)
		if "occupied_by" in model_data:
			spot.occupying_player = _actors.get(model_data["occupied_by"]["id"])
			spot.update_appearance()
	else:
		var spot = Spot.instantiate()
		spot.spot_number = model_data["spot_number"]
		spot.position = Vector2(
		   model_data["instanced_entity"]["x"],
		   model_data["instanced_entity"]["y"] )
		
		spot.connect("spot_occupied", Callable(self, "_on_spot_occupied"))
		spot.connect("spot_occupied", Callable(self, "_on_spot_occupied"))
		
		_spots[model_id] = spot
		add_child(spot)
		
			
	

func _update_tictactoegame(model_id: int, model_data: Dictionary):	
	print("Game table data:", model_data)  # Debug print
	# Create visual representation of game table
	if model_id in _tables:
		var table = _tables[model_id]
		
		if model_data.get("is_active"):
			var player1_id = model_data.get("player1_id")
			var player2_id = model_data.get("player2_id")
			if not _tic_tac_toe:
				_start_tic_tac_toe(player1_id, player2_id)
			else:
				if _tic_tac_toe:
					_finish_tic_tac_toe(player1_id, player2_id)
	else:	
		var table = Area2D.new()	
		var visual = ColorRect.new()
		visual.size = Vector2(200, 200)
		visual.position = Vector2(-100, -100)
		visual.color = Color(0, 0.5, 0, 0.3)  # Green, semi-transparent	
		table.add_child(visual)
		
		# Set position from model data
		table.position = Vector2(	
				model_data["instanced_entity"]["x"],	
				model_data["instanced_entity"]["y"]		
				)	
		add_child(table)

func _check_for_game_start():
	var occupied_spots = 0
	for spot in _spots.values():
		if spot.is_occupied:
			occupied_spots += 1
		if occupied_spots == 2:
			# Both spots occupied, ready to play
			pass

func _enter_game():
	state = Callable(self, "PLAY")

	# Remove the login screen
	remove_child(_login_screen)

	# Instance the chatbox
	_chatbox = Chatbox.instantiate()
	_chatbox.connect("message_sent", Callable(self, "send_chat"))
	add_child(_chatbox)
	_ui = ui.instantiate()
	add_child(_ui)
#TICTACTOE-----------------------------------
	var spot1 = Spot.instantiate()
	spot1.spot_number = 1
	#add_child(spot1)
	spot1.position = Vector2(150, 300)
	#spot1.set_network_client(_network_client)
	var spot2 = Spot.instantiate()
	spot2.spot_number = 2
	#add_child(spot2)
	spot2.position = Vector2(450, 300)
	
	add_child(spot1)
	add_child(spot2)
	
	var table1 = Table.instantiate()
	add_child(table1)
	table1.position = Vector2(250,300)
	


func send_chat(text: String):
	var p: Packet = Packet.new("Chat", [_username, text])
	_network_client.send_packet(p)
	_chatbox.add_message(_username, text)


func _handle_client_connected():
	print("Client connected to server!")


func _handle_client_disconnected(was_clean: bool):
	OS.alert("Disconnected %s" % ["cleanly" if was_clean else "unexpectedly"])
	get_tree().quit()


func _handle_network_data(data: String):
	print("Received server data: ", data)
	var action_payloads: Array = Packet.json_to_action_payloads(data)
	var p: Packet = Packet.new(action_payloads[0], action_payloads[1])
	# Pass the packet to our current state
	state.call(p)


func _handle_network_error():
	OS.alert("There was an error")


func _unhandled_input(event: InputEvent):
	if _player_actor and event.is_action_released("click"):
		var target = _player_actor.body.get_global_mouse_position()
		_player_actor._player_target = target
		var p: Packet = Packet.new("Target", [target.x, target.y])
		_network_client.send_packet(p)

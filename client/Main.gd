extends Node

# Imports
const NetworkClient = preload("res://websockets_client.gd")
const Packet = preload("res://packet.gd")
const Chatbox = preload("res://Chatbox.tscn")
const ui = preload("res://ui/UI.tscn")
#const Actor = preload("res://Actor.tscn")
const Character = preload("res://Character.tscn")
const FriendlyNPC = preload("res://FriendlyNPC.tscn")
const EnemyNPC = preload("res://EnemyNPC.tscn")

@onready var _network_client = NetworkClient.new()
@onready var _login_screen = get_node("Login")

var _chatbox = null
var state: Callable
var _username: String
#var _actors: Dictionary = {}
var _characters: Dictionary = {}
var _npcs: Dictionary = {}
var _enemies: Dictionary = {}
var _items: Dictionary = {}
var _quests: Dictionary = {}
var _guilds: Dictionary = {}
#var _player_actor = null
var _ui = null

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
		"ModelDelta":
			_update_models(p.payloads[0])
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
			var character_id: int = p.payloads[0]
			if character_id in _characters:
				var character = _characters[character_id]
				_chatbox.add_message(null, character.character_name + " has disconnected.")
				remove_child(character)
				_characters.erase(character_id)
		"Attack":
			var character_id: int = p.payloads[0]
			var target_character_id: int = p.payloads[1]
			var damage: int = p.payloads[2]
			if character_id in _characters and target_character_id in _characters:
				var attacker = _characters[character_id]
				var target = _characters[target_character_id]
				target.take_damage(damage)
		"Heal":
			var character_id: int = p.payloads[0]
			var target_character_id: int = p.payloads[1]
			var healing: int = p.payloads[2]
			if character_id in _characters and target_character_id in _characters:
				var healer = _characters[character_id]
				var target = _characters[target_character_id]
				target.receive_healing(healing)
		"Die":
			var character_id: int = p.payloads[0]
			if character_id in _characters:
				var character = _characters[character_id]
				_chatbox.add_message(null, character.character_name + " has died.")
				if character.is_player:
					_ui.show_death_screen()
		"CreateGuild":
			var guild_data: Dictionary = p.payloads[0]
			_update_guild(guild_data["id"], guild_data)
		"JoinGuild":
			var character_id: int = p.payloads[0]
			var guild_id: int = p.payloads[1]
			if character_id in _characters and guild_id in _guilds:
				var character = _characters[character_id]
				var guild_data = _guilds[guild_id]
				character.update({"guild": guild_data})
		"LeaveGuild":
			var character_id: int = p.payloads[0]
			if character_id in _characters:
				var character = _characters[character_id]
				character.update({"guild": null})
		"GetQuest":
			var character_id: int = p.payloads[0]
			var quest_id: int = p.payloads[1]
			if quest_id not in _quests:
				_quests[quest_id] = {"active": true}
			_ui.update_quests(_quests)
		"CompleteQuest":
			var character_id: int = p.payloads[0]
			var quest_id: int = p.payloads[1]
			if quest_id in _quests:
				_quests[quest_id]["active"] = false
				_quests[quest_id]["complete"] = true
			_ui.update_quests(_quests)
		"GetItem":
			var character_id: int = p.payloads[0]
			var item_id: int = p.payloads[1]
			var quantity: int = p.payloads[2]
			if item_id not in _items:
				_items[item_id] = quantity
			else:
				_items[item_id] += quantity
		"LoseItem":
			var character_id: int = p.payloads[0]
			var item_id: int = p.payloads[1]
			var quantity: int = p.payloads[2]
			if item_id in _items:
				_items[item_id] = max(0, _items[item_id] - quantity)
				if _items[item_id] == 0:
					_items.erase(item_id)
		"TalkFriendlyNPC":
			var character_id: int = p.payloads[0]
			var npc_id: int = p.payloads[1]
			if npc_id in _npcs:
				var npc = _npcs[npc_id]
				_ui.show_npc_dialogue(npc)


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
	match model_data["model_type"]:
		"Character":
			_update_character(model_data["id"], model_data)
		#"Actor":
			#_update_actor(model_data["id"], model_data)
		"Guild":
			_update_guild(model_data["id"], model_data)
		"Quest":
			_update_quest(model_data["id"], model_data)
		"FriendlyNPC":
			_update_friendly_npc(model_data["id"], model_data)
		"EnemyNPC":
			_update_enemy_npc(model_data["id"], model_data)


#func _update_actor(model_id: int, model_data: Dictionary):
	## If this is an existing actor, just update them
	#if model_id in _actors:
		#_actors[model_id].update(model_data)
	## If this actor doesn't exist in the game yet, create them
	#else:
		#var new_actor
		#if not _player_actor: 
			#_player_actor = Actor.instantiate().init(model_data)
			#_player_actor.is_player = true
			#new_actor = _player_actor
		#else:
			#new_actor = Actor.instantiate().init(model_data)
		#_actors[model_id] = new_actor
		#add_child(new_actor)

func _update_character(model_id: int, model_data: Dictionary):
	if model_id in _characters:
		_characters[model_id].update(model_data)
	else:
		var new_character = Character.instantiate().init(model_data)
		# Set is_player if this character belongs to the player
		if model_data.has("user") and model_data["user"].has("username"):
			if model_data["user"]["username"] == _username:
				new_character.is_player = true
				# Make sure camera is enabled
				var camera = new_character.get_node("CharacterBody2D/Camera2D")
				if camera:
					camera.enabled = true
		_characters[model_id] = new_character
		add_child(new_character)

func _update_guild(model_id: int, model_data: Dictionary):
	if model_id in _guilds:
		_guilds[model_id].update(model_data)
	else:
		_guilds[model_id] = model_data
		_ui.update_guilds(_guilds)

func _update_quest(model_id: int, model_data: Dictionary):
	_quests[model_id] = model_data
	_ui.update_quests(_quests)

func _update_friendly_npc(model_id: int, model_data: Dictionary):
	if model_id in _npcs:
		_npcs[model_id].update(model_data)
	else:
		var new_npc = FriendlyNPC.instantiate().init(model_data)
		_npcs[model_id] = new_npc
		add_child(new_npc)

func _update_enemy_npc(model_id: int, model_data: Dictionary):
	if model_id in _enemies:
		_enemies[model_id].update(model_data)
	else:
		var new_enemy = EnemyNPC.instantiate().init(model_data)
		_enemies[model_id] = new_enemy
		add_child(new_enemy)

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
	if event.is_action_released("click"):
		for character in _characters.values():
			if character.is_player:
				var target = character.body.get_global_mouse_position()
				character._player_target = target
				var p: Packet = Packet.new("Target", [target.x, target.y])
				_network_client.send_packet(p)
				break

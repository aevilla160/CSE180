extends Control

# UI Elements
@onready var info = $CanvasLayer/Panel/VBoxContainer/Info
@onready var hp_bar = $CanvasLayer/Panel/VBoxContainer/HealthBar
@onready var mp_bar = $CanvasLayer/Panel/VBoxContainer/ManaBar
@onready var xp_bar = $CanvasLayer/Panel/VBoxContainer/XPBar

@onready var ability1 = get_node("CanvasLayer/ActionBar/GridContainer/Ability1/Ability1Button")
@onready var ability2 = get_node("CanvasLayer/ActionBar/GridContainer/Ability2/Ability2Button")
@onready var ability3 = get_node("CanvasLayer/ActionBar/GridContainer/Ability3/Ability3Button")
@onready var ability4 = get_node("CanvasLayer/ActionBar/GridContainer/Ability4/Ability4Button")
@onready var ability5 = get_node("CanvasLayer/ActionBar/GridContainer/Ability5/Ability5Button")

@onready var stats_panel = $CanvasLayer/StatsPanel
@onready var guild_label = $CanvasLayer/Panel/VBoxContainer/GuildInfo
@onready var death_screen = $CanvasLayer/DeathScreen
@onready var level_up_notification = $CanvasLayer/LevelUpNotification
@onready var dialogue_panel = $CanvasLayer/DialoguePanel

@export var inventory: Inventory

var _username: String = ""
var _player_character = null

var ability_cooldowns = {
	"attack": 0.0,
	"heal": 0.0,
	"special1": 0.0,
	"special2": 0.0,
	"special3": 0.0
}

func _ready():
	$CanvasLayer/DialoguePanel/VBoxContainer/CloseButton.pressed.connect(hide_npc_dialogue)
	$CanvasLayer/DeathScreen/VBoxContainer/RespawnButton.pressed.connect(hide_death_screen)
	
	ability1.pressed.connect(_on_ability1_pressed)
	ability2.pressed.connect(_on_ability2_pressed)
	ability3.pressed.connect(_on_ability3_pressed)
	ability4.pressed.connect(_on_ability4_pressed)
	ability5.pressed.connect(_on_ability5_pressed)
	
	# Hide optional panels
	death_screen.hide()
	dialogue_panel.hide()
	level_up_notification.hide()

	# Wait a frame for player to be ready
	await get_tree().create_timer(0.1).timeout
	_connect_to_player()

func _connect_to_player():
	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:
		_player_character = player[0]
		# Connect character signals
		_player_character.health_changed.connect(_on_health_changed)
		_player_character.mana_changed.connect(_on_mana_changed)
		_player_character.xp_gained.connect(_on_xp_gained)
		_player_character.level_up.connect(_on_level_up)
		
		# Initialize bars
		_on_health_changed(_player_character.hp, _player_character.get_max_hp())
		_on_mana_changed(_player_character.mp, _player_character.get_max_mp())
		_on_xp_gained(_player_character.xp, _player_character.calculate_required_xp())

func update_character_stats(stats: Dictionary):
	if not _player_character:
		return

	if stats.has("class"):
		update_info(_username, stats["class"])
	
	if stats.has("guild"):
		if stats["guild"]:
			var guild_name = stats["guild"]["guild_name"]
			guild_label.text = "[%s]" % [guild_name]
			guild_label.show()
		else:
			guild_label.hide()
			
	update_stats_panel()

func update_info(username: String, char_class: String):
	if _username == "":
		_username = username
	
	info.text = "%s - %s - Level %i" % [username, char_class, _player_character.level]

func update_stats_panel():
	if not _player_character:
		return
		
	stats_panel.get_node("Stats").text = """
	Level: %d
	XP: %d / %d
	Vitality: %d
	Strength: %d
	Magic: %d
	""" % [
		_player_character.level,
		_player_character.xp,
		_player_character.calculate_required_xp(),
		_player_character.vitality,
		_player_character.strength,
		_player_character.magic
	]

# Signal handlers
func _on_health_changed(current: int, maximum: int):
	hp_bar.max_value = maximum
	hp_bar.value = current

func _on_mana_changed(current: int, maximum: int):
	mp_bar.max_value = maximum
	mp_bar.value = current

func _on_xp_gained(current: int, required: int):
	xp_bar.max_value = required
	xp_bar.value = current

func _on_level_up(new_level: int):
	show_level_up_notification()
	update_stats_panel()

# UI Display Functions
func show_level_up_notification():
	level_up_notification.get_node("Label").text = "Level Up! You are now level %d!" % _player_character.level
	level_up_notification.show()
	await get_tree().create_timer(3.0).timeout
	level_up_notification.hide()

func show_death_screen():
	death_screen.show()

func hide_death_screen():
	death_screen.hide()

func show_npc_dialogue(npc):
	dialogue_panel.get_node("NPCName").text = npc.actor_name
	dialogue_panel.get_node("NPCRole").text = npc.npc_role
	dialogue_panel.show()

func hide_npc_dialogue():
	dialogue_panel.hide()

# Ability System
func update_ability_cooldowns(delta: float):
	for ability in ability_cooldowns.keys():
		if ability_cooldowns[ability] > 0:
			ability_cooldowns[ability] = max(0, ability_cooldowns[ability] - delta)
			update_ability_button_state(ability)

func update_ability_button_state(ability: String):
	var button = get_node("CanvasLayer/ActionBar/GridContainer/" + ability.capitalize() + "/" + ability.capitalize() + "Button")
	button.disabled = ability_cooldowns[ability] > 0
	if button.disabled:
		button.text = "%.1fs" % ability_cooldowns[ability]
	else:
		button.text = ability.capitalize()

func _on_ability1_pressed():
	# Basic attack
	if ability_cooldowns["attack"] <= 0:
		ability_cooldowns["attack"] = 1.0
		get_tree().call_group("player", "try_attack")

func _on_ability2_pressed():
	# Heal spell
	if ability_cooldowns["heal"] <= 0 and _player_character.mp >= 2:
		ability_cooldowns["heal"] = 2.0
		get_tree().call_group("player", "try_cast_spell")

func _on_ability3_pressed():
	if ability_cooldowns["special1"] <= 0:
		ability_cooldowns["special1"] = 5.0
		# Implement special ability 1

func _on_ability4_pressed():
	if ability_cooldowns["special2"] <= 0:
		ability_cooldowns["special2"] = 5.0
		# Implement special ability 2

func _on_ability5_pressed():
	if ability_cooldowns["special3"] <= 0:
		ability_cooldowns["special3"] = 5.0
		# Implement special ability 3

func _process(delta):
	update_ability_cooldowns(delta)

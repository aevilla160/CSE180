extends "res://Actor.gd"

signal health_changed(current_health: int, max_health: int)
signal mana_changed(current_mana: int, max_mana: int)
signal xp_gained(current_xp: int, required_xp: int)
signal level_up(new_level: int)

# Character Stats
var level: int = 1
var xp: int = 0
var hp: int = 100
var mp: int = 5
var vitality: int = 10
var strength: int = 1
var magic: int = 1
var character_class: String = ""
var character_name: String = ""
var guild_name: String = ""

# UI Elements
@onready var camera = get_node("CharacterBody2D/Camera2D")
@onready var health_bar = get_node("CharacterBody2D/StatusBars/HealthBar")
@onready var mana_bar = get_node("CharacterBody2D/StatusBars/ManaBar")
@onready var level_label = get_node("CharacterBody2D/Label")

# Combat state
var is_attacking: bool = false
var attack_range: float = 60.0
var attack_cooldown: float = 1.0
var time_since_last_attack: float = 0.0

func _ready():
	super._ready()
	print("Character ready, is_player: ", is_player)
	if is_player:
		print("Enabling camera for player character")
		if camera:
			camera.enabled = true
	if health_bar:
		health_bar.max_value = hp
		health_bar.value = hp
	if mana_bar:
		mana_bar.max_value = mp
		mana_bar.value = mp
	if level_label:
		level_label.text = "Lv.%s" % [level]
	#if is_player and camera:
		#camera.enabled = true


func calculate_required_xp() -> int:
	return round(pow(level, 1.8) + level * 4 + 8)


func update(new_model: Dictionary):
	super.update(new_model)
	
	var stats_changed = false
	
	# Update character stats
	if new_model.has("level"):
		level = new_model["level"]
		level_label.text = "Lv.%s" % [level]
		stats_changed = true
		
	if new_model.has("xp"):
		xp = new_model["xp"]
		emit_signal("xp_gained", xp, calculate_required_xp())
		
	if new_model.has("hp"):
		hp = new_model["hp"]
		health_bar.value = hp
		emit_signal("health_changed", hp, health_bar.max_value)
		stats_changed = true
		
	if new_model.has("mp"):
		mp = new_model["mp"]
		mana_bar.value = mp
		emit_signal("mana_changed", mp, mana_bar.max_value)
		stats_changed = true
		
	if new_model.has("vitality"):
		vitality = new_model["vitality"]
		stats_changed = true
		
	if new_model.has("strength"):
		strength = new_model["strength"]
		stats_changed = true
		
	if new_model.has("magic"):
		magic = new_model["magic"]
		stats_changed = true
		
	if new_model.has("character_class"):
		character_class = new_model["character_class"]
		
	if new_model.has("character_name"):
		character_name = new_model["character_name"]
		label.text = "%s\n%s Lv.%s" % [character_name, character_class, level]
		
	if new_model.has("guild"):
		if new_model["guild"]:
			guild_name = new_model["guild"]["guild_name"]
			label.text = "%s [%s]\n%s Lv.%s" % [character_name, guild_name, character_class, level]
		else:
			guild_name = ""
			
	#if stats_changed:
		#update_stat_display()

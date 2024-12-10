extends "res://Character.gd"

func _ready():
	super._ready()
	# Set up visual distinction for other players
	sprite.modulate = Color(0.9, 0.9, 1.0)  # Slight blue tint

func take_damage(damage: int):
	# Update visuals only, server handles actual damage
	animation_player.play("hit")
	
func receive_healing(healing: int):
	# Update visuals only, server handles actual healing
	animation_player.play("heal")

func calculate_required_xp() -> int:
	# Simple exponential XP requirement
	return level * level * 100

func update_stat_display():
	if is_player:
		# Update detailed stats in UI
		get_tree().call_group("ui", "update_character_stats", {
			"level": level,
			"xp": xp,
			"hp": hp,
			"mp": mp,
			"vitality": vitality,
			"strength": strength,
			"magic": magic,
			"class": character_class
		})

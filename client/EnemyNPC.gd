extends "res://Actor.gd"

var enemy_health: int = 10
var attack_damage: int = 1
var attack_range: float = 50.0
var attack_cooldown: float = 1.0
var time_since_last_attack: float = 0.0
var is_attacking: bool = false
var dropped_item = null

func _ready():
	super._ready()
	#sprite.modulate = Color(1, 0.7, 0.7)
	is_enemy = true
	speed = enemy_speed

func update(new_model: Dictionary):
	super.update(new_model)
	
	if new_model.has("enemy_health"):
		enemy_health = new_model["enemy_health"]
		
	if new_model.has("enemy_name"):
		actor_name = new_model["enemy_name"]
		if label:
			label.text = "%s\nHP: %s" % [actor_name, enemy_health]
			
	if new_model.has("enemy_item"):
		dropped_item = new_model["enemy_item"]

func _physics_process(delta):
	super._physics_process(delta)
	
	# Update attack cooldown
	if time_since_last_attack < attack_cooldown:
		time_since_last_attack += delta
	
	# Check for attack opportunities
	if active_target and time_since_last_attack >= attack_cooldown:
		var distance = body.position.distance_to(active_target.position)
		if distance <= attack_range:
			attack()

func attack():
	if not is_attacking:
		is_attacking = true
		time_since_last_attack = 0
		
		# Play attack animation
		animation_player.play("attack")
		
		# Send attack packet to server
		if active_target.get("actor_id"):
			var packet = load("res://packet.gd").new()
			packet.init("Attack", [self.get("actor_id"), active_target.actor_id, attack_damage])
			get_tree().get_node("/root/Main").get_node("NetworkClient").send_packet(packet)

func take_damage(damage: int):
	enemy_health -= damage
	if label:
		label.text = "%s\nHP: %s" % [actor_name, enemy_health]
	
	if enemy_health <= 0:
		die()

func die():
	# Send die packet to server
	var packet = load("res://packet.gd").new()
	packet.init("Die", [self.get("actor_id")])
	get_tree().get_node("/root/Main").get_node("NetworkClient").send_packet(packet)
	
	# Drop item if we have one
	if dropped_item:
		# Implement item dropping logic here
		pass
	
	# Queue for removal
	queue_free()

func _on_animation_finished(anim_name: String):
	if anim_name == "attack":
		is_attacking = false

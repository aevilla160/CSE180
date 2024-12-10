extends "res://Character.gd"

func _ready():
	super._ready()
	is_player = true
	# Add player-specific UI elements
	var camera = Camera2D.new()
	camera.make_current()
	body.add_child(camera)

func _input(event):
	if event.is_action_pressed("attack"):
		try_attack()
	elif event.is_action_pressed("cast_spell"):
		try_cast_spell()

func _physics_process(delta):
	super._physics_process(delta)
	
	# Update attack cooldown
	if time_since_last_attack < attack_cooldown:
		time_since_last_attack += delta

func try_attack():
	if time_since_last_attack < attack_cooldown:
		return
		
	# Find closest enemy in range
	var closest_enemy = null
	var closest_distance = attack_range
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance = body.position.distance_to(enemy.body.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	if closest_enemy:
		time_since_last_attack = 0
		animation_player.play("attack")
		
		# Calculate damage based on strength
		var damage = 5 + strength * 2
		
		# Send attack packet
		var packet = load("res://packet.gd").new()
		packet.init("Attack", [self.get("actor_id"), closest_enemy.get("actor_id"), damage])
		get_tree().get_node("/root/Main").get_node("NetworkClient").send_packet(packet)

func try_cast_spell():
	if mp < 2:
		return
		
	# Find closest target in range
	var closest_target = null
	var closest_distance = attack_range * 1.5  # Longer range for spells
	
	for target in get_tree().get_nodes_in_group("characters"):
		var distance = body.position.distance_to(target.body.position)
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
	
	if closest_target:
		mp -= 2
		animation_player.play("cast")
		
		# Calculate healing based on magic
		var healing = 10 + magic * 3
		
		# Send heal packet
		var packet = load("res://packet.gd").new()
		packet.init("Heal", [self.get("actor_id"), closest_target.get("actor_id"), healing])
		get_tree().get_node("/root/Main").get_node("NetworkClient").send_packet(packet)
		
		emit_signal("mana_changed", mp, mana_bar.max_value)

func take_damage(damage: int):
	hp -= damage
	health_bar.value = hp
	emit_signal("health_changed", hp, health_bar.max_value)
	
	if hp <= 0:
		die()

func receive_healing(healing: int):
	hp = min(hp + healing, health_bar.max_value)
	health_bar.value = hp
	emit_signal("health_changed", hp, health_bar.max_value)

func die():
	# Send die packet
	var packet = load("res://packet.gd").new()
	packet.init("Die", [self.get("actor_id")])
	get_tree().get_node("/root/Main").get_node("NetworkClient").send_packet(packet)
	
	# Handle death (respawn, show death screen, etc.)
	get_tree().call_group("ui", "show_death_screen")

extends "res://Actor.gd"

var npc_role: String = ""
var dialogue_active: bool = false
var interaction_area: Area2D

func _ready():
	super._ready()
	interaction_area = get_node("InteractionArea")
	sprite.modulate = Color(0.7, 1, 0.7)  # Slight green tint to indicate friendly
	speed = 25.0  # Slower movement for NPCs

func update(new_model: Dictionary):
	super.update(new_model)
	
	if new_model.has("npc_role"):
		npc_role = new_model["npc_role"]
		
	if new_model.has("npc_name"):
		actor_name = new_model["npc_name"]
		if label:
			label.text = "%s\n(%s)" % [actor_name, npc_role]

func _physics_process(delta):
	# Override parent _physics_process to implement NPC-specific movement patterns
	if not dialogue_active:
		# Implement basic patrolling or stationary behavior
		if server_position:
			var distance = body.position.distance_to(server_position)
			if distance > 5:
				velocity = (server_position - body.position).normalized() * speed
				body.set_velocity(velocity)
				body.move_and_slide()
			else:
				velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

func start_dialogue():
	dialogue_active = true
	# Signal to UI to show dialogue window
	get_tree().call_group("ui", "show_npc_dialogue", self)

func end_dialogue():
	dialogue_active = false
	# Signal to UI to hide dialogue window
	get_tree().call_group("ui", "hide_npc_dialogue")

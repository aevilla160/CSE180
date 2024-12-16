#Create Rock Paper Scissors where it is played with 2 players over network
#The game will have a lobby where players can join and leave

extends Node
@onready var game_status = $CanvasLayer/VBoxContainer/StatusLabel
@onready var choice_container = $CanvasLayer/VBoxContainer/ChoiceContainer
@onready var rock_button = $CanvasLayer/VBoxContainer/ChoiceContainer/RockButton
@onready var paper_button = $CanvasLayer/VBoxContainer/ChoiceContainer/PaperButton
@onready var scissors_button = $CanvasLayer/VBoxContainer/ChoiceContainer/ScissorsButton
@onready var result_label = $CanvasLayer/VBoxContainer/ResultLabel

var player_choice = ""
var opponent_choice = ""
var game_in_progress = false

signal choice_made(choice)

func _ready():
	rock_button.connect("pressed", Callable(self, "_on_choice_made").bind("rock"))
	paper_button.connect("pressed", Callable(self, "_on_choice_made").bind("paper"))
	scissors_button.connect("pressed", Callable(self, "_on_choice_made").bind("scissors"))
	
	# Initially disable choice buttons until game starts
	set_buttons_enabled(false)

func _on_choice_made(choice: String):
	if not game_in_progress:
		return
		
	player_choice = choice
	set_buttons_enabled(false)
	emit_signal("choice_made", choice)
	game_status.text = "Waiting for opponent..."

func start_game():
	game_in_progress = true
	player_choice = ""
	opponent_choice = ""
	result_label.text = ""
	game_status.text = "Make your choice!"
	set_buttons_enabled(true)

func handle_opponent_choice(choice: String):
	opponent_choice = choice
	determine_winner()

func determine_winner():
	var result = ""
	
	if player_choice == opponent_choice:
		result = "It's a tie!"
	elif (player_choice == "rock" and opponent_choice == "scissors") or \
		 (player_choice == "paper" and opponent_choice == "rock") or \
		 (player_choice == "scissors" and opponent_choice == "paper"):
		result = "You win!"
	else:
		result = "Opponent wins!"
	
	result_label.text = result
	#game_status.text = f"You chose {player_choice}, opponent chose {opponent_choice}"
	game_in_progress = false

func set_buttons_enabled(enabled: bool):
	rock_button.disabled = not enabled
	paper_button.disabled = not enabled
	scissors_button.disabled = not enabled

func reset_game():
	game_in_progress = false
	player_choice = ""
	opponent_choice = ""
	result_label.text = ""
	game_status.text = "Make your choice!"
	set_buttons_enabled(true)

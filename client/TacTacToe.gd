extends Control

const TicTacToeGame = preload("res://TicTacToeGame.gd")
const Packet = preload("res://packet.gd")


@onready var board_grid: GridContainer = $BoardGrid
@onready var x_wins_label: Label = $ScoreContainer/XWinsLabel
@onready var o_wins_label: Label = $ScoreContainer/OWinsLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var match_over_panel: Panel = $MatchOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var match_over_label: Label = $MatchOverPanel/MatchOverLabel

var game: TicTacToeGame
var cell_buttons: Array = []

var my_turn = false
var my_id = -1


func _ready():
	# Initialize game
	game = TicTacToeGame.new()
	add_child(game)
	
	# Connect game signals
	game.connect("move_made", Callable(self, "_on_move_made"))
	game.connect("game_ended", Callable(self, "_on_game_ended"))
	game.connect("match_ended", Callable(self, "_on_match_ended"))
	
	# Create grid buttons
	_create_board_buttons()
	
	# Initialize score labels
	_update_score_labels()
	
	# Hide game over panels
	game_over_panel.hide()
	match_over_panel.hide()

func _create_board_buttons():
	# Clear any existing buttons
	for child in board_grid.get_children():
		child.queue_free()
	
	cell_buttons.clear()
	
	# Create 3x3 grid of buttons
	for i in range(3):
		var row_buttons = []
		for j in range(3):
			var button = Button.new()
			button.custom_minimum_size = Vector2(100, 100)  # Fixed size
			button.flat = false  # Remove this line or set to false to make button visible
			# Add some styling
			button.add_theme_color_override("font_color", Color.YELLOW)
			button.add_theme_font_size_override("font_size", 40)  # Bigger X and O
			button.connect("pressed", Callable(self, "_on_cell_pressed").bind(i, j))
			board_grid.add_child(button)
			row_buttons.append(button)
		cell_buttons.append(row_buttons)

func _on_cell_pressed(row: int, col: int):
	# Attempt to make a move
	if my_turn:
		#if game.make_move(row, col):
			#_update_board_ui()
		var network_client = get_node("/root/Main/_network_client")
		var p = Packet.new("TicTacToeMove", [row, col])
		network_client.send_packet(p)	

func _on_move_made(row: int, col: int, player: int):
	# Update specific cell when a move is made
	var symbol = "X" if player == 1 else "O"  # 1 is Player.X
	cell_buttons[row][col].text = symbol

func _update_board_ui():
	# Update all cells on the board
	for i in range(3):
		for j in range(3):
			var cell_value = game.board[i][j]
			var symbol = ""
			match cell_value:
				1:  # Player.X
					symbol = "X"
				2:  # Player.O
					symbol = "O"
			cell_buttons[i][j].text = symbol

func handle_network_move(row: int, col: int, player_id: int):
	# Make the move
	game.make_move(row,col)
	_update_board_ui()
	 # Update whose turn it is based on the player who just moved
	my_turn = my_id != player_id
	
func game_start(player1_id: int, player2_id: int):
	my_id = get_node("root/Main")._actor.id
	my_turn = my_id == player1_id
	visible = true	
func _update_score_labels():
	x_wins_label.text = "X Wins: %d" % game.x_wins
	o_wins_label.text = "O Wins: %d" % game.o_wins

func _on_game_ended(result: int):
	# Show game over panel
	game_over_panel.show()
	
	match result:
		1:  # GameResult.X_WINS
			game_over_label.text = "X Wins!"
		2:  # GameResult.O_WINS
			game_over_label.text = "O Wins!"
		3:  # GameResult.DRAW
			game_over_label.text = "Draw!"
	
	# Disable board
	_set_board_interaction(false)

func _on_match_ended(winner: int):
	# Hide game over panel
	game_over_panel.hide()
	
	# Show match over panel
	match_over_panel.show()
	
	match winner:
		1:  # Player.X
			match_over_label.text = "X Wins the Match!"
		2:  # Player.O
			match_over_label.text = "O Wins the Match!"

func _set_board_interaction(enable: bool):
	for row in cell_buttons:
		for button in row:
			button.disabled = not enable

func _on_continue_button_pressed():
	# Hide game over panel
	game_over_panel.hide()
	
	# Reset for next game
	_create_board_buttons()
	game.reset_game()
	_set_board_interaction(true)
	_update_score_labels()

func _on_rematch_button_pressed():
	# Reset entire match
	game.request_rematch()
	
	# Hide match over panel
	match_over_panel.hide()
	
	# Reset board and interactions
	_create_board_buttons()
	_set_board_interaction(true)
	_update_score_labels()

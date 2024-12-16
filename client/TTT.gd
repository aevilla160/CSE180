extends Control

# A two-player Tic-Tac-Toe setup.
# Player 'X' will go first, then 'O'. We track moves to determine winners.

# Tracks the current player symbol: 'X' or 'O'
var current_player: String = "X"

# Stores the board state. We'll keep a 2D array representing each cell.
# Initialize empty cells with "".
var board_state: Array = [
	["", "", ""],
	["", "", ""],
	["", "", ""]
]

# Reference to the GridContainer that holds the buttons
var board_container: GridContainer

func _ready():
	# Setup the UI layout
	create_board()

func create_board():
	# Create a GridContainer (3x3) for the tic-tac-toe board
	board_container = GridContainer.new()
	board_container.columns = 3
	board_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_container.anchor_left = 0.5
	board_container.anchor_top = 0.5
	board_container.anchor_right = 0.5
	board_container.anchor_bottom = 0.5
	board_container.position = Vector2(-150, -150)  # Center offset for a 300x300 grid (assuming defaults)
	board_container.custom_min_size = Vector2(300, 300)
	add_child(board_container)

	# Instantiate 9 buttons for the board
	for row in range(3):
		for col in range(3):
			var cell_button = Button.new()
			cell_button.text = ""    # Initially empty
			cell_button.name = "Cell_%d_%d" % [row, col]
			cell_button.connect("pressed", Callable(self, "_on_cell_pressed").bind(row, col))
			board_container.add_child(cell_button)

func _on_cell_pressed(row: int, col: int):
	# Get the button that was pressed
	var cell_button = get_node("%s/Cell_%d_%d" % [board_container.get_path(), row, col])

	# Check if cell is empty before making a move
	if board_state[row][col] == "":
		# Mark the cell with the current player's symbol
		board_state[row][col] = current_player
		cell_button.text = current_player
		cell_button.disabled = true  # Prevent changes to this cell again
		
		# Check for a winner
		if check_winner(current_player):
			show_winner_popup(current_player)
		else:
			# If no winner yet, switch player
			current_player = if current_player == "X": "O" else "X"

func check_winner(player_symbol: String) -> bool:
	# Check rows
	for i in range(3):
		if board_state[i][0] == player_symbol and board_state[i][1] == player_symbol and board_state[i][2] == player_symbol:
			return true

	# Check columns
	for j in range(3):
		if board_state[0][j] == player_symbol and board_state[1][j] == player_symbol and board_state[2][j] == player_symbol:
			return true

	# Check diagonals
	if board_state[0][0] == player_symbol and board_state[1][1] == player_symbol and board_state[2][2] == player_symbol:
		return true
	if board_state[0][2] == player_symbol and board_state[1][1] == player_symbol and board_state[2][0] == player_symbol:
		return true

	return false

func show_winner_popup(player_symbol: String):
	var popup = AcceptDialog.new()
	add_child(popup)
	popup.dialog_text = "Player '%s' wins!" % player_symbol
	popup.connect("confirmed", Callable(self, "_on_new_game"))
	popup.popup_centered()

func _on_new_game():
	# Reset board state
	board_state = [
		["", "", ""],
		["", "", ""],
		["", "", ""]
	]
	current_player = "X"

	# Reset buttons
	for child in board_container.get_children():
		if child is Button:
			child.text = ""
			child.disabled = false

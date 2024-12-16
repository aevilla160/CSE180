class_name TicTacToeGame
extends Node

signal move_made(row, col, player)
signal game_ended(result)
signal match_ended(winner)
signal rematch_request

enum Player { NONE, X, O }
enum GameResult { ONGOING, X_WINS, O_WINS, DRAW }

var board: Array = []
var current_player: Player = Player.X
var game_result: GameResult = GameResult.ONGOING

# Track wins across multiple games
var x_wins: int = 0
var o_wins: int = 0
const WINS_TO_MATCH_END: int = 2

func _init():
	reset_game()

func reset_game():
	# Create 3x3 grid of empty cells
	board = [
		[Player.NONE, Player.NONE, Player.NONE],
		[Player.NONE, Player.NONE, Player.NONE],
		[Player.NONE, Player.NONE, Player.NONE]
	]
	current_player = Player.X
	game_result = GameResult.ONGOING
#-------
	
func make_move(row: int, col: int) -> bool:
	# Validate move
	if not is_valid_move(row, col):
		return false
	
	# Place move
	board[row][col] = current_player
	
	# Emit move signal for potential network or UI updates
	emit_signal("move_made", row, col, current_player)
	
	# Check game state
	_update_game_state()
	
	# Switch players
	current_player = Player.O if current_player == Player.X else Player.X
	
	return true

func is_valid_move(row: int, col: int) -> bool:
	# Check move is within board
	if row < 0 or row > 2 or col < 0 or col > 2:
		return false
	
	# Check cell is empty
	return board[row][col] == Player.NONE

func _update_game_state():
	var result = _check_win()
	if result != GameResult.ONGOING:
		game_result = result
		_handle_game_result(result)
	elif _is_board_full():
		# If board is full but no winner, it's a draw
		game_result = GameResult.DRAW
		_handle_game_result(GameResult.DRAW)

func _handle_game_result(result: GameResult):
	match result:
		GameResult.X_WINS:
			x_wins += 1
			emit_signal("game_ended", result)
			_check_match_end(Player.X)
		GameResult.O_WINS:
			o_wins += 1
			emit_signal("game_ended", result)
			_check_match_end(Player.O)
		GameResult.DRAW:
			# Reset for another game if it's a draw
			emit_signal("game_ended", result)
			reset_game()

func _check_match_end(winner: Player):
	# Check if a player has reached the win threshold
	if x_wins >= WINS_TO_MATCH_END or o_wins >= WINS_TO_MATCH_END:
		emit_signal("match_ended", winner)

func _check_win() -> GameResult:
	# Check rows
	for row in board:
		if row[0] != Player.NONE and row[0] == row[1] and row[0] == row[2]:
			return row[0] as GameResult
	
	# Check columns
	for col in range(3):
		if board[0][col] != Player.NONE and board[0][col] == board[1][col] and board[0][col] == board[2][col]:
			return board[0][col] as GameResult
	
	# Check diagonals
	if board[0][0] != Player.NONE and board[0][0] == board[1][1] and board[0][0] == board[2][2]:
		return board[0][0] as GameResult
	
	if board[0][2] != Player.NONE and board[0][2] == board[1][1] and board[0][2] == board[2][0]:
		return board[0][2] as GameResult
	
	return GameResult.ONGOING

func _is_board_full() -> bool:
	for row in board:
		for cell in row:
			if cell == Player.NONE:
				return false
	return true

func request_rematch():
	# Reset game state
	x_wins = 0
	o_wins = 0
	reset_game()
	
	# Signal that a rematch is requested
	emit_signal("rematch_request")

func get_game_state() -> Dictionary:
	return {
		"board": board,
		"current_player": current_player,
		"game_result": game_result,
		"x_wins": x_wins,
		"o_wins": o_wins
	}

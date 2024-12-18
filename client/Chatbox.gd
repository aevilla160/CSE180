extends Control

@onready var chat_log = get_node("CanvasLayer/VBoxContainer/RichTextLabel")
@onready var input_label = get_node("CanvasLayer/VBoxContainer/HBoxContainer/Label")
@onready var input_field = get_node("CanvasLayer/VBoxContainer/HBoxContainer/LineEdit")
@onready var button = get_node("CanvasLayer/VBoxContainer/HBoxContainer/Button")

signal message_sent(message)


func _ready():
	input_field.connect("text_submitted", Callable(self, "text_submitted"))
	button.connect("pressed", Callable(self, "button_pressed"))


func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				input_field.grab_focus()
			KEY_ESCAPE:
				input_field.release_focus()


func add_message(username, text: String):
	if username:
		if text == "<3": 
			chat_log.text += "[color=red]" + username + "[/color] says: " + "\u2665" + "\n"		
		elif text == ":)"	:
			chat_log.text += "[color=green]" + username + "[/color] says: " + "😀" + "\n"
		elif text == ";)"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😉" + "\n"
		elif text == "B)"	:
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😎" + "\n"
		elif text == ">:("	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😠" + "\n"
		elif text == ":|"	:
			chat_log.text += "[color=white]" + username + "[/color] says: " + "😐" + "\n"
		elif text == ":("	:
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😔" + "\n"
		elif text == ":,("	:
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😢" + "\n"
		elif text == "(:"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "🙃" + "\n"
		elif text == ":P"	:
			chat_log.text += "[color=pink]" + username + "[/color] says: " + "😛" + "\n"
		elif text == ":o"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😯" + "\n"
		elif text == "XD"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😆" + "\n"
		elif text == ":3"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😗" + "\n"	
		elif text == "0_0"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😳" + "\n"	
		elif text == "ToT"	:
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😭" + "\n"	
		elif text == ">w<"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😫" + "\n"	
		elif text == "0//0"	:
			chat_log.text += "[color=red]" + username + "[/color] says: " + "😳" + "\n"
		elif text == "Ammon":
			chat_log.text += "[color=green]" + username + "[/color] says: " + "🐐" + "\n"
		elif text == "Test":
			chat_log.text += "[color=white]" + username + "[/color] says: " + text + "\n"
			chat_log.text += "[color=purple]" + "Dev" + "[/color] says: " + "[color=purple]" +  "0/10 You Failed" + "[/color]" + "\n"
		elif text == "Hello":
			chat_log.text += "[color=white]" + username + "[/color] says: " + text + "\n"
			chat_log.text += "[color=purple]" + "Dev" + "[/color] says: "  +  "Hi "+ "[color=purple]" + username + "[/color]" + "\n"
		elif text == "-_-":
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😑" + "\n"
		elif text == ":D":
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😃" + "\n"
		elif text == "^_^":
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😁" + "\n"
		elif text == "8)":
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "🤓" + "\n"
		elif text == "Bye":
			chat_log.text += "[color=white]" + username + "[/color] says: " + text + "\n"
			chat_log.text += "[color=purple]" + "Dev" + "[/color] says: " + "[color=purple]" +  "See You Later" + "[/color]" + "\n"
		elif text == ";p":
			chat_log.text += "[color=blue]" + username + "[/color] says: " + "😜" + "\n"
		elif text == "Alex":
			chat_log.text += "[color=white]" + username + "[/color] says: " + text + "\n"
			chat_log.text += "[color=purple]" + "Dev" + "[/color] says: " + "[color=purple]" +  "Parallel Computing" + "[/color]" + "\n"
		elif text == "Armando":
			chat_log.text += "[color=white]" + username + "[/color] says: " + text + "\n"
			chat_log.text += "[color=purple]" + "Dev" + "[/color] says: " + "[color=purple]" +  "RIP TicTacToe" + "[/color]" + "\n"
		elif text == "Jeffrey":
			chat_log.text += "[color=white]" + username + "[/color] says: " + text + "\n"
			chat_log.text += "[color=purple]" + "Dev" + "[/color] says: " + "[color=purple]" +  "Please Don't Sue Nintendo" + "[/color]" + "\n"
		
		
		

		else:	
			chat_log.text += username + ' says: "' + text + '"\n'
	else:
		# Server message
		chat_log.text += "[color=yellow]" + text + "[/color]\n" 


func text_submitted(text: String):
	if len(text) > 0:
		input_field.text = ""

		emit_signal("message_sent", text)

func button_pressed():
	text_submitted(input_field.text)

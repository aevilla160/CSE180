extends Control

@onready var inventory: Inventory = preload("res://inventory/player_inventory.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()
@onready var inventory_open_sound = $InventoryOpenSound
@onready var inventory_close_sound = $InventoryCloseSound

var is_open = false

func _ready() -> void:
	inventory.update.connect(update_slots)
	update_slots()
	close()


func update_slots():
	for i in range(min(inventory.slots.size(), slots.size())):
		slots[i].update(inventory.slots[i])


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("i"):
		if is_open:
			close()
		else:
			open()


func open():
	inventory_open_sound.play()
	visible = true
	is_open = true


func close():
	inventory_close_sound.play()
	visible = false
	is_open = false

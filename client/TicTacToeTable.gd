extends Area2D

var spots_in_range = {
	1: false,
	2: false
}

func _ready():
	# Make table visible with a different color than spots
	var visual = ColorRect.new()
	visual.size = Vector2(200, 200)  # Bigger than spots
	visual.position = Vector2(300, 300)  # Center it
	visual.color = Color(0, 0.5, 0, 0.3)  # Green with transparency
	add_child(visual)

	# Set up collision for spot detection
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(600, 600)  # Area big enough to detect both spots
	collision.shape = shape
	add_child(collision)

	connect("area_entered", Callable(self, "_on_area_entered"))
	connect("area_exited", Callable(self, "_on_area_exited"))

func _on_area_entered(area: Area2D):
	print("Area entered:", area.name)  # Debug print
	if area.has_method("get_spot_number"):
		var spot_number = area.get_spot_number()
		spots_in_range[spot_number] = true
		print("Spot", spot_number, "deteced in range")  # Debug print

func _on_area_exited(area: Area2D):
	if area.has_method("get_spot_number"):
		var spot_number = area.get_spot_number()
		spots_in_range[spot_number] = false
		print("Spot", spot_number, "left range")  # Debug print

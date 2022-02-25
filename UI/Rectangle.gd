extends Node2D

var corner_a = Vector2():
	get:
		return corner_a
	set(new_corner):
		corner_a = new_corner
		update()
var corner_b = Vector2():
	get:
		return corner_b
	set(new_corner):
		corner_b = new_corner
		update()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _draw():
	var min_x = min(corner_a.x, corner_b.x)
	var max_x = max(corner_a.x, corner_b.x)
	var min_y = min(corner_a.y, corner_b.y)
	var max_y = max(corner_a.y, corner_b.y)
	
	draw_line(Vector2(min_x, min_y), Vector2(max_x, min_y), Color.GREEN, 1.0)
	draw_line(Vector2(max_x, min_y), Vector2(max_x, max_y), Color.GREEN, 1.0)
	draw_line(Vector2(max_x, max_y), Vector2(min_x, max_y), Color.GREEN, 1.0)
	draw_line(Vector2(min_x, max_y), Vector2(min_x, min_y), Color.GREEN, 1.0)

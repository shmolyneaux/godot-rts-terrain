extends Node3D
class_name Tower

var hovered = false:
	get:
		return hovered
	set(new_hovered):
		hovered = new_hovered
		_update_selection_circle()


var selected = false:
	get:
		return selected
	set(new_selected):
		selected = new_selected
		_update_selection_circle()


var last_event_mouse_position = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	_update_selection_circle()


func _update_selection_circle():
	$Decal.visible = selected or hovered
	if selected:
		$Decal.modulate.a = 1.0
	elif hovered:
		$Decal.modulate.a = 0.25

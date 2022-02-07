extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_rts_terrain_input_event(camera, event, position, normal):
	if normal.y != 0:
		global_transform.origin = position

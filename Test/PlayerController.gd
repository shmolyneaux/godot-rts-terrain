extends Node

var building = preload("res://Test/Tower.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_rts_terrain_input_event(camera, event, position, normal):
	position = position.snapped(Vector3(1, 1, 1))
	$BuildingPlacement.global_transform.origin = position
	if event is InputEventMouseButton:
		if event.pressed:
			var terrain = get_parent().get_node("RtsTerrain")
			var tile = terrain.global_to_tile(position)
			
			if event.button_index == 1:
				var tower = building.instantiate()
				terrain.add_child(tower)
				tower.global_transform.origin = position
				terrain.set_hole(tile.x, tile.y, true)

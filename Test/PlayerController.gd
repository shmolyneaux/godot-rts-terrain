extends Node

var building = preload("res://Test/Tower.tscn")

func _on_rts_terrain_input_event(camera, event, position, normal):
	position = position.snapped(Vector3(1, 1, 1))
	$Brush.global_transform.origin = position
	if event is InputEventMouseButton:
		if event.pressed:
			var terrain = get_parent().get_node("RtsTerrain")
			var tile = terrain.global_to_tile(position)
			
			if event.button_index == 1:
				var tower = building.instantiate()
				terrain.add_child(tower)
				tower.global_transform.origin = position
				terrain.set_hole(tile.x, tile.y, true)

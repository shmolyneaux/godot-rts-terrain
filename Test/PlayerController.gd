extends Node3D

var building = preload("res://Test/Tower.tscn")

var _mouse_last_world_position = Vector3()
var _brush_position = Vector3():
	get:
		return _brush_position
	set(new_position):
		$Brush.global_transform.origin = new_position
		_brush_position = new_position
var _brush_terrain_target = null
var _brush_visible = false:
	get:
		return _brush_visible
	set(visible):
		$Brush.visible = visible
		_brush_visible = visible

var _selection_box = null
var _state = null
var _click_start = null
var _mouse_current = Vector2()

func _input(event):
	if ActivePlayer.mode == ActivePlayer.BUILD_MODE:
		if event.is_action("ui_cancel") and event.pressed:
			ActivePlayer.mode = ActivePlayer.NORMAL_MODE
		
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == 1 and _brush_visible and _brush_terrain_target:
				if ActivePlayer.attempt_deduct_gold(30):
					var tile = _brush_terrain_target.global_to_tile(_brush_position)
					var tower = building.instantiate()
					_brush_terrain_target.add_child(tower)
					tower.global_transform.origin = _brush_position
					_brush_terrain_target.set_hole(tile.x, tile.y, true)

	elif ActivePlayer.mode == ActivePlayer.NORMAL_MODE:
		if event.is_action("ui_cancel") and event.pressed:
			for node in get_tree().get_nodes_in_group("buildings"):
				node.selected = false
		elif event is InputEventMouseButton:
			if event.button_index == 1:
				if event.pressed:
					# Left mouse button pressed
					_selection_box = $Rectangle
					_selection_box.corner_a = event.position
					_selection_box.corner_b = event.position
				if not event.pressed:
					# Left mouse button released
					for node in get_tree().get_nodes_in_group("buildings"):
						node.selected = node.hovered
						node.hovered = false
					_selection_box.corner_a = event.position
					_selection_box.corner_b = event.position
					_selection_box = null
		elif event is InputEventMouseMotion:
			if _selection_box:
				_selection_box.corner_b = event.position


func _physics_process(delta):
	var space_state = get_world_3d().direct_space_state
	var camera: Camera3D = get_viewport().get_camera_3d()

	for node in get_tree().get_nodes_in_group("buildings"):
		node.hovered = false

	if _selection_box:
		var boxed_things = PhysicsUtils3D.intersect_camera_frustum(
			camera,
			$Rectangle.corner_a,
			$Rectangle.corner_b
		)
		
		for thing in boxed_things:
			if thing.collider is Tower:
				thing.collider.hovered = true

	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = camera.project_ray_origin(get_viewport().get_mouse_position())
	ray.to = camera.project_ray_normal(get_viewport().get_mouse_position())*1000.0

	var node = null
	var hit = Vector3()
	var result = space_state.intersect_ray(ray)
	if result:
		node = result.collider
		hit = result.position

	# Find the type of node that's responsible for this collider if the top-level
	# node for the object isn't the collider itself

	# Get the terrain node from its collider
	if node and node.is_in_group("terrain_collider"):
		while node and (not node is RtsTerrain):
			node = node.get_parent()
	
	if node is RtsTerrain:
		if ActivePlayer.mode == ActivePlayer.BUILD_MODE:
			_brush_terrain_target = node
			_brush_position = hit.snapped(Vector3(1, 1, 1))
			_brush_visible = true
		else:
			_brush_visible = false

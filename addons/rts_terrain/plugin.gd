@tool
extends EditorPlugin

var editing_object: RtsTerrain = null

var recent_mouse_origin = Vector3()
var recent_mouse_normal = Vector3()

var set_cliff_level = 0
var mouse_held = true

# Tile under the mouse for the terrain that's currently being edited. This gets
# cleared whenever the mouse moves.
var active_tile = null

enum TerrainTool {
	RAISE_CLIFF=0,
	LOWER_CLIFF=1,
	CREATE_RAMP=2,
	REMOVE_RAMP=3,
	RAISE_TERRAIN=4,
	LOWER_TERRAIN=5,
	SMOOTH_TERRAIN=6,
}
var active_tool = TerrainTool.RAISE_CLIFF

func terrain_input_event():
	print("got input event from terrain!")

var terrain_brush_scene = preload("res://addons/rts_terrain/Brush.tscn")
var terrain_brush = null
var editor_dock_scene = preload("res://addons/rts_terrain/TerrainEditorDock.tscn")
var editor_dock = null

func _handles(object):
	return object is RtsTerrain

func _edit(object):
	editing_object = object

func _make_visible(visible):
	if visible:
		_create_controls()
	else:
		_clear_controls()

func _create_controls():
	if editor_dock:
		return
	
	editor_dock = editor_dock_scene.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, editor_dock)
	editor_dock.connect("tool_changed", _tool_changed)
	
	terrain_brush = terrain_brush_scene.instantiate()
	editing_object.add_child(terrain_brush)
	
func _clear_controls():
	if editor_dock:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_SIDE_RIGHT, editor_dock)
		editor_dock.queue_free()
		editor_dock = null
		terrain_brush.queue_free()
		terrain_brush = null

func _forward_3d_gui_input(viewport_camera: Camera3D, event):
	var handled = false
	if event is InputEventMouseMotion:
		active_tile = null
		recent_mouse_origin = viewport_camera.project_ray_origin(event.position)
		recent_mouse_normal = viewport_camera.project_ray_normal(event.position)
		handled = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		
	if event is InputEventMouseButton and active_tile:
		# TODO: only handle the release if the press was also handled
		handled = event.button_index == MOUSE_BUTTON_LEFT
		mouse_held == event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var ramp_removal_cliff_level = 10000
			var left = editing_object.get_cliff(active_tile.x-1, active_tile.y)
			var right = editing_object.get_cliff(active_tile.x+1, active_tile.y)
			var up = editing_object.get_cliff(active_tile.x, active_tile.y-1)
			var down = editing_object.get_cliff(active_tile.x, active_tile.y+1)
			if up != -1:
				ramp_removal_cliff_level = min(ramp_removal_cliff_level, up)
			if down != -1:
				ramp_removal_cliff_level = min(ramp_removal_cliff_level, down)
			if left != -1:
				ramp_removal_cliff_level = min(ramp_removal_cliff_level, left)
			if right != -1:
				ramp_removal_cliff_level = min(ramp_removal_cliff_level, right)
				
			if ramp_removal_cliff_level == 10000:
				ramp_removal_cliff_level = 0
			
			if active_tool == TerrainTool.RAISE_CLIFF:
				# NOTE: member variable
				set_cliff_level = editing_object.get_cliff(active_tile.x, active_tile.y)
				if set_cliff_level == -1:
					set_cliff_level = ramp_removal_cliff_level + 1
				else:
					set_cliff_level = set_cliff_level + 1
				editing_object.set_cliff(
					active_tile.x,
					active_tile.y,
					set_cliff_level
				)
			if active_tool == TerrainTool.LOWER_CLIFF:
				# NOTE: member variable
				set_cliff_level = editing_object.get_cliff(active_tile.x, active_tile.y)
				if set_cliff_level == -1:
					set_cliff_level = ramp_removal_cliff_level
				else:
					set_cliff_level = max(set_cliff_level - 1, 0)
				
				editing_object.set_cliff(
					active_tile.x,
					active_tile.y,
					set_cliff_level
				)
			if active_tool == TerrainTool.CREATE_RAMP:
				set_cliff_level = -1
				editing_object.set_cliff(
					active_tile.x,
					active_tile.y,
					-1
				)
			if active_tool == TerrainTool.REMOVE_RAMP:
				set_cliff_level = ramp_removal_cliff_level
				editing_object.set_cliff(
					active_tile.x,
					active_tile.y,
					ramp_removal_cliff_level
				)
			if active_tool == TerrainTool.RAISE_TERRAIN:
				var new_height
				for offset in [[0,0], [0,1], [1,1], [1,0]]:
					new_height = 0.1 + editing_object.get_height(
						active_tile.x + offset[0],
						active_tile.y + offset[1],
					)
					editing_object.set_height(
						active_tile.x + offset[0],
						active_tile.y + offset[1],
						new_height
					)
			if active_tool == TerrainTool.LOWER_TERRAIN:
				var new_height
				for offset in [[0,0], [0,1], [1,1], [1,0]]:
					new_height = -0.1 + editing_object.get_height(
						active_tile.x + offset[0],
						active_tile.y + offset[1],
					)
					editing_object.set_height(
						active_tile.x + offset[0],
						active_tile.y + offset[1],
						new_height
					)
			active_tile = null
		
	return handled
	
func _physics_process(delta):
	# If we're actively editing and the mouse has just moved then we want to
	# get the tile under the cursor.
	if editing_object and editor_dock and not active_tile:
		var space_state = editing_object.get_world_3d().direct_space_state
		var ray = PhysicsRayQueryParameters3D.new()
		ray.from = recent_mouse_origin
		ray.to = recent_mouse_origin + recent_mouse_normal * 1000
		var result = space_state.intersect_ray(ray)
		if result != {}:
			if result.collider.get_parent().get_parent() == editing_object:
				active_tile = editing_object.global_to_tile(result.position)
				terrain_brush.global_transform.origin = editing_object.tile_to_global(active_tile)
				
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					if active_tool in [
						TerrainTool.RAISE_CLIFF,
						TerrainTool.LOWER_CLIFF,
						TerrainTool.CREATE_RAMP,
						TerrainTool.REMOVE_RAMP,
					]:
						editing_object.set_cliff(
							active_tile.x,
							active_tile.y,
							set_cliff_level
						)
					
					if active_tool == TerrainTool.RAISE_TERRAIN:
						var new_height
						for offset in [[0,0], [0,1], [1,1], [1,0]]:
							new_height = 0.02 + editing_object.get_height(
								active_tile.x + offset[0],
								active_tile.y + offset[1],
							)
							editing_object.set_height(
								active_tile.x + offset[0],
								active_tile.y + offset[1],
								new_height
							)
					if active_tool == TerrainTool.LOWER_TERRAIN:
						var new_height
						for offset in [[0,0], [0,1], [1,1], [1,0]]:
							new_height = -0.02 + editing_object.get_height(
								active_tile.x + offset[0],
								active_tile.y + offset[1],
							)
							editing_object.set_height(
								active_tile.x + offset[0],
								active_tile.y + offset[1],
								new_height
							)
					if active_tool == TerrainTool.SMOOTH_TERRAIN:
						var total_height = 0
						for offset in [[0,0], [0,1], [1,1], [1,0]]:
							total_height += editing_object.get_height(
								active_tile.x + offset[0],
								active_tile.y + offset[1],
							)
						var average = total_height / 4
						for offset in [[0,0], [0,1], [1,1], [1,0]]:
							var height = editing_object.get_height(
								active_tile.x + offset[0],
								active_tile.y + offset[1],
							)
							editing_object.set_height(
								active_tile.x + offset[0],
								active_tile.y + offset[1],
								height*0.9 + average*0.1
							)

func _tool_changed(tool):
	print("Tool changed to: ", tool)
	active_tool = tool

func _exit_tree():
	_clear_controls()

func _disable_plugin():
	_clear_controls()

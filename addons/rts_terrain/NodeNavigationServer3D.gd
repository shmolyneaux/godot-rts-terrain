extends Node

var astar = AStar.new()
var _debug_mesh: ImmediateMesh = ImmediateMesh.new()

var _node_id_to_navigation_id = {}

var _debug_icons = []
var _id_to_debug_icon = {}

var debug_draw: bool = false:
	get:
		return debug_draw
	set(v):
		debug_draw = v
		if debug_draw:
			_redraw_debug()
		else:
			for node in _debug_icons:
				node.queue_free()
			_debug_icons = []
			_debug_mesh.clear_surfaces()
			_id_to_debug_icon = {}

func add_node(node: NavigationNode3D):
	var id = astar.get_available_point_id()
	_node_id_to_navigation_id[node.get_instance_id()] = id
	
	astar.add_point(id, node.global_transform.origin)
	astar.set_point_disabled(id, node.disabled)
	
	var material = StandardMaterial3D.new()
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _debug_mesh
	add_child(mesh_instance)

	_redraw_debug()
	
	
func node_moved(node: NavigationNode3D, new_position: Vector3):
	var id = _node_id_to_navigation_id[node.get_instance_id()]
	astar.set_point_position(id, new_position)
	if id in _id_to_debug_icon:
		_id_to_debug_icon[id].position = new_position
	_redraw_debug_lines()
	
	
func node_enabled(node: NavigationNode3D, enabled: bool):
	var id = _node_id_to_navigation_id[node.get_instance_id()]
	astar.set_point_disabled(id, not enabled)
	if id in _id_to_debug_icon:
		if enabled:
			_id_to_debug_icon[id].modulate = Color.WHITE
		else:
			_id_to_debug_icon[id].modulate = Color.DIM_GRAY


func remove_node(node: NavigationNode3D):
	var id = _node_id_to_navigation_id[node.get_instance_id()]
	astar.remove_point(id)
	_node_id_to_navigation_id.erase(node.get_instance_id())
	if id in _id_to_debug_icon:
		_id_to_debug_icon[id].modulate = Color.BLACK
		_id_to_debug_icon.erase(id)

func connect_nodes(a: NavigationNode3D, b: NavigationNode3D):
	astar.connect_points(
		_node_id_to_navigation_id[a.get_instance_id()],
		_node_id_to_navigation_id[b.get_instance_id()]
	)
	_redraw_debug()

func _redraw_debug_lines():
	if debug_draw:
		_debug_mesh.clear_surfaces()
		_debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

		for id in astar.get_point_ids():
			var position = astar.get_point_position(id)
			for connected_id in astar.get_point_connections(id):
				# Don't draw lines both ways
				if connected_id < id:
					if astar.is_point_disabled(id) or astar.is_point_disabled(connected_id):
						_debug_mesh.surface_set_color(Color.DARK_RED)
					else:
						_debug_mesh.surface_set_color(Color.WHITE)
					_debug_mesh.surface_add_vertex(Vector3(0, 0.1, 0) + position)
					_debug_mesh.surface_add_vertex(Vector3(0, 0.1, 0) + astar.get_point_position(connected_id))

		_debug_mesh.surface_end()

		var material = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true

		if _debug_mesh.get_surface_count():
			_debug_mesh.surface_set_material(0, material)


func _redraw_debug_icons():
	return
	if debug_draw:
		for node in _debug_icons:
			node.queue_free()
		_debug_icons = []
		
		for id in astar.get_point_ids():
			var position = astar.get_point_position(id)
			var icon = Sprite3D.new()
			add_child(icon)
			icon.global_transform.origin = position
			icon.texture = preload("res://addons/rts_terrain/apple.png")
			icon.billboard = true
			icon.pixel_size = 0.005
			if astar.is_point_disabled(id):
				icon.modulate = Color.DIM_GRAY
			_debug_icons.append(icon)
			_id_to_debug_icon[id] = icon

func _redraw_debug():
	_redraw_debug_icons()
	_redraw_debug_lines()


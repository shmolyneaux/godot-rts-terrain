@tool
class_name RtsTerrain
extends Node3D

const RAMP = -1

const ROTATION_MASK = 0b011_00000_00000000_00000000_00000000
enum {
	ROT_0=0b000_00000_00000000_00000000_00000000,
	ROT_90=0b001_00000_00000000_00000000_00000000,
	ROT_180=0b010_00000_00000000_00000000_00000000,
	ROT_270=0b011_00000_00000000_00000000_00000000,
}

const MODEL_MASK = 0b0000_1111_00000000_00000000_00000000
enum {
	NO_MODEL=          0b0000_0000_00000000_00000000_00000000,
	RAMP_LOWER_LEFT=   0b0000_0001_00000000_00000000_00000000,
	RAMP_LOWER_RIGHT=  0b0000_0010_00000000_00000000_00000000,
	RAMP_UPPER_LEFT=   0b0000_0011_00000000_00000000_00000000,
	RAMP_UPPER_RIGHT=  0b0000_0100_00000000_00000000_00000000,
	CLIFF_SIDE=        0b0000_0101_00000000_00000000_00000000,
	CLIFF_CORNER_OUTER=0b0000_0110_00000000_00000000_00000000,
	CLIFF_CORNER_INNER=0b0000_0111_00000000_00000000_00000000,
	RAMP_LOWER=        0b0000_1000_00000000_00000000_00000000,
	RAMP_UPPER=        0b0000_1001_00000000_00000000_00000000,
}

const CLIFF_LEVEL_MASK = 0b00000000_00000000_00000000_11111111

@export var material: Material = null
@export var cliff_material: Array[Material] = []
@export var outer_corner: Mesh = null
@export var inner_corner: Mesh = null
@export var side: Mesh = null
@export var upper_left_ramp: Mesh = null
@export var upper_right_ramp: Mesh = null
@export var lower_left_ramp: Mesh = null
@export var lower_right_ramp: Mesh = null
@export var generate_navigation_region: bool = true
@export var generate_static_physics_body: bool = true
@export var debug_draw_navigation: bool = false:
	get:
		return debug_draw_navigation
	set(v):
		debug_draw_navigation = v
		_regenerate_mesh()
@export var debug_draw_collider: bool = false:
	get:
		return debug_draw_collider
	set(v):
		debug_draw_collider = v
		_regenerate_mesh()
@export var hide_decorative_layer: bool = false:
	get:
		return hide_decorative_layer
	set(v):
		hide_decorative_layer = v
		_regenerate_mesh()


var managed_children = []

# TODO: Seems like the "TerrainData" should be a resource?
var terrain = TerrainData.new()
@export var width: int:
	get:
		return terrain.width
	set(v):
		terrain.width = v
		_regenerate_mesh()
		
@export var height: int:
	get:
		return terrain.height
	set(v):
		terrain.height = v
		_regenerate_mesh()
		
@export var terrain_cliffs: PackedInt32Array:
	get:
		return terrain.data
	set(v):
		if v.size() != width * height:
			print("new terrain of size ", v.size(), " doesn't match size: ", width*height)
		else:
			terrain.data = v
			_regenerate_mesh()
			
			
@export var terrain_height: PackedFloat32Array:
	get:
		return terrain.heightmap
	set(v):
		if v.size() != (width+1) * (height+1):
			print("new terrain of size ", v.size(), " doesn't match size: ", (width+1)*(height+1))
		else:
			terrain.heightmap = v
			_regenerate_mesh()


var placeholder_mesh = BoxMesh.new()

var _navigation_nodes = {}

signal input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3)

class TileCoord:
	var x = 0
	var y = 0

func global_to_tile(coord: Vector3) -> TileCoord:
	var output = TileCoord.new()
	
	output.x = round(coord.x)
	output.y = round(coord.z)
	
	return output
	
func tile_to_global(coord: TileCoord) -> Vector3:
	var output = TileCoord.new()
	
	var cliff_level = terrain.get_cliff_level(coord.x, coord.y)
	if cliff_level == -1:
		var ramp_cliff_level_sum = 0
		var real_tile_count = 0
		
		var left = get_cliff(coord.x-1, coord.y)
		var right = get_cliff(coord.x+1, coord.y)
		var up = get_cliff(coord.x, coord.y-1)
		var down = get_cliff(coord.x, coord.y+1)
		if up != -1:
			ramp_cliff_level_sum += up
			real_tile_count += 1
		if down != -1:
			ramp_cliff_level_sum += down
			real_tile_count += 1
		if left != -1:
			ramp_cliff_level_sum += left
			real_tile_count += 1
		if right != -1:
			ramp_cliff_level_sum += right
			real_tile_count += 1
			
		if real_tile_count:
			cliff_level = ramp_cliff_level_sum / real_tile_count
		
	return Vector3(coord.x, cliff_level, coord.y)
	
func is_hole(x: int, y: int) -> bool:
	return terrain.is_hole(x, y)
	
func set_hole(x: int, y: int, value: int):
	terrain.set_hole(x, y, value)
	_navigation_nodes[Vector3i(x, y, 0)].disabled = value
	
	# Recompute diagonals
	var diagonals = [
		[x, y],
		[x+1, y],
		[x+1, y+1],
		[x, y+1],
	]
	for diag in diagonals:
		var idx = Vector3i(diag[0], diag[1], 1)
		if idx in _navigation_nodes:
			if (
				terrain.is_navigable(diag[0], diag[1])
				and terrain.is_navigable(diag[0]-1, diag[1])
				and terrain.is_navigable(diag[0]-1, diag[1]-1)
				and terrain.is_navigable(diag[0], diag[1]-1)
			):
				_navigation_nodes[idx].disabled = false
			else:
				_navigation_nodes[idx].disabled = true
		
	NodeNavigationServer3D._redraw_debug_lines()
	
func get_cliff(x: int, y: int) -> int:
	return terrain.get_cliff_level(x, y)
	
func set_cliff(x: int, y: int, value: int):
	terrain.set_cliff_level(x, y, value)
	_regenerate_mesh()
	
func get_height(x: int, y: float) -> float:
	return terrain.get_terrain_height(x, y)
	
func set_height(x: int, y: int, value: float):
	terrain.set_terrain_height(x, y, value)	
	_regenerate_mesh()

static func _create_tri_face(
	sts: Array,
	points: Array,
	uvs: Array = [
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(0, 1),
	]
):
	assert(points.size() == 3)
	var normal = (points[0] - points[1]).cross(points[2] - points[0]).normalized()
	
	for st in sts:
		for idx in range(3):
			st.set_normal(normal)
			st.set_uv(uvs[idx])
			st.add_vertex(points[idx])


static func _create_quad_face(
	sts: Array,
	points: Array
):
	assert(points.size() == 4)
	var height = (points[0] - points[3]).length()
	_create_tri_face(
		sts,
		[points[0], points[1], points[3]],
		[
			Vector2(0, 0),
			Vector2(1, 0),
			Vector2(0, height),
		],
	)
	_create_tri_face(
		sts,
		[points[2], points[3], points[1]],
		[
			Vector2(1, height),
			Vector2(0, height),
			Vector2(1, 0),
		],
	)


static func _create_ramp(
	st,
	xform,
	hide_tri_0=true,
	hide_tri_1=true,
):
	_create_quad_face(
		st,
		[
			xform * Vector3(-0.5, 1, -0.5),
			xform * Vector3(+0.5, 1, -0.5),
			xform * Vector3(+0.5, 0, +0.5),
			xform * Vector3(-0.5, 0, +0.5),
		]
	)
	

	if not hide_tri_0:
		_create_tri_face(
			st,
			[
				xform * Vector3(-0.5, 1, -0.5),
				xform * Vector3(-0.5, 0, +0.5),
				xform * Vector3(-0.5, 0, -0.5),
			]
		)
	if not hide_tri_1:
		_create_tri_face(
			st,
			[
				xform * Vector3(+0.5, 1, -0.5),
				xform * Vector3(+0.5, 0, -0.5),
				xform * Vector3(+0.5, 0, +0.5),
			]
		)
	
	
static func _create_ramp_corner(
	st,
	xform,
	hide_tri_0=true,
	hide_tri_1=true,
):
	_create_tri_face(
		st,
		[
			xform * Vector3(-0.5, 1, -0.5),
			xform * Vector3(+0.5, 1, -0.5),
			xform * Vector3(+0.5, 0, +0.5),
		]
	)
	_create_tri_face(
		st,
		[
			xform * Vector3(-0.5, 1, +0.5),
			xform * Vector3(-0.5, 1, -0.5),
			xform * Vector3(+0.5, 0, +0.5),
		]
	)

	if not hide_tri_0:
		_create_tri_face(
			st,
			[
				xform * Vector3(-0.5, 1, +0.5),
				xform * Vector3(+0.5, 0, +0.5),
				xform * Vector3(-0.5, 0, +0.5),
			]
		)
	if not hide_tri_1:
		_create_tri_face(
			st,
			[
				xform * Vector3(+0.5, 1, -0.5),
				xform * Vector3(+0.5, 0, -0.5),
				xform * Vector3(+0.5, 0, +0.5),
			]
		)

func _enter_tree():
	_regenerate_mesh()


class TerrainData:
	var _width: int = 1
	var width:
		get:
			return _width
		set(new_width):
			resize(new_width, height)

	var _height: int = 1
	var height:
		get:
			return _height
		set(new_height):
			resize(width, new_height)

	var _data: PackedInt32Array = PackedInt32Array([0])
	var data: PackedInt32Array:
		get:
			return _data
		set(v):
			if v.size() == _data.size():
				_data = v
			else:
				print("mismatched terrain size!")
				
	var _holes: PackedInt32Array = PackedInt32Array([0])
	var holes: PackedInt32Array:
		get:
			return _holes
		set(v):
			if v.size() == _holes.size():
				_holes = v
			else:
				print("mismatched terrain hole size!")
				
	var _heightmap: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var heightmap: PackedFloat32Array:
		get:
			return _heightmap
		set(v):
			if v.size() == _heightmap.size():
				_heightmap = v
			else:
				print("mismatched terrain heightmap size!")
	
	func resize(new_width, new_height):
		var new_data = []
		var new_holes = []
		var new_heightmap = []
		new_data.resize(new_width*new_height)
		new_holes.resize(new_width*new_height)
		new_heightmap.resize((new_width+1)*(new_height+1))
		
		for x in range(new_width):
			for y in range(new_height):
				new_data[x + y*new_width] = get_cliff_level(x, y)
				new_holes[x + y*new_width] = is_hole(x, y)
				
		for x in range(new_width+1):
			for y in range(new_height+1):
				new_heightmap[x + y*(new_width+1)] = get_terrain_height(x, y)
				
		_data = PackedInt32Array(new_data)
		_holes = PackedInt32Array(new_holes)
		_heightmap = PackedFloat32Array(new_heightmap)
		_width = new_width
		_height = new_height
		
	func set_cliff_level(x: int, y: int, value: int):
		if x < 0 or width <= x:
			print(x, " ", y, " out of range")
			return
		if y < 0 or height <= y:
			print(x, " ", y, " out of range")
			return

		var idx = x + y*width
		_data[idx] = value
	
	func get_cliff_level(x: int, y: int) -> int:
		if x < 0 or width <= x:
			return 0
		if y < 0 or height <= y:
			return 0

		var idx = x + y*width
		return _data[idx]
		
	func get_data(x: int, y: int) -> int:
		if x < 0 or width <= x:
			return 0
		if y < 0 or height <= y:
			return 0

		var idx = x + y*width
		return _data[idx]
		
	func set_hole(x: int, y: int, value: int):
		if x < 0 or width <= x:
			print(x, " ", y, " out of range")
			return
		if y < 0 or height <= y:
			print(x, " ", y, " out of range")
			return

		var idx = x + y*width
		_holes[idx] = value
		
	func is_hole(x: int, y: int):
		if x < 0 or width <= x:
			return false
		if y < 0 or height <= y:
			return false

		var idx = x + y*width
		return _holes[idx]
		
	func is_navigable(x: int, y: int):
		var tile_data = get_data(x, y)
		var model = tile_data & MODEL_MASK
		return model in [NO_MODEL, RAMP_LOWER, RAMP_UPPER] and not is_hole(x, y)
		
	func set_terrain_height(x: int, y: int, value: float):
		if x < 0 or width + 1 <= x:
			print(x, " ", y, " out of range")
			return
		if y < 0 or height + 1 <= y:
			print(x, " ", y, " out of range")
			return

		var idx = x + y*(width+1)
		_heightmap[idx] = value
	
	func get_terrain_height(x: int, y: int) -> float:
		if x < 0 or width + 1 <= x:
			return 0.0
		if y < 0 or height + 1 <= y:
			return 0.0

		var idx = x + y*(width+1)
		return _heightmap[idx]


static func ramp_offset(model, rotation):
	var tl = 0.0
	var tr = 0.0
	var bl = 0.0
	var br = 0.0
	match model:
		RAMP_UPPER:
			tl = 1.0
			tr = 1.0
			bl = 0.5
			br = 0.5
		RAMP_LOWER:
			tl = 0.5
			tr = 0.5
	
	match rotation:
		ROT_90:
			return {
				"tl": bl,
				"tr": tl,
				"bl": br,
				"br": tr,
			}
		ROT_180:
			return {
				"tl": br,
				"tr": bl,
				"bl": tr,
				"br": tl,
			}
		ROT_270:
			return {
				"tl": tr,
				"tr": br,
				"bl": tl,
				"br": bl,
			}
	
	return {
		"tl": tl,
		"tr": tr,
		"bl": bl,
		"br": br,
	}


static func interp_quad(x, y, verts) -> Vector3:
	assert(verts.size() == 4)
	var tl = verts[0]
	var tr = verts[1]
	var br = verts[2]
	var bl = verts[3]
	
	if (x+y) < 1.0:
		var bary_a_area = 1.0 - x - y
		var bary_b_area = x
		var bary_c_area = y
		return bary_a_area*tl + bary_b_area*tr + bary_c_area*bl
	else:
		var bary_d_area = x + y - 1.0;
		var bary_b_area = 1.0 - y;
		var bary_c_area = 1.0 - x;
		return bary_d_area*br + bary_b_area*tr + bary_c_area*bl


func generate_mesh(terrain_data):
	var mesh_instances = []
	var view_st = SurfaceTool.new()
	var navmesh_st = SurfaceTool.new()
	var physics_st = SurfaceTool.new()

	view_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	navmesh_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	physics_st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(terrain_data.width):
		for y in range(terrain_data.height):
			var tile_data = terrain_data.get_data(x, y)
			var tl = terrain_data.get_terrain_height(x, y)
			var tr = terrain_data.get_terrain_height(x+1, y)
			var bl = terrain_data.get_terrain_height(x, y+1)
			var br = terrain_data.get_terrain_height(x+1, y+1)
			
			var cliff_level = tile_data & 0b111
			var ground_sts = [physics_st, view_st]
			var model = tile_data & MODEL_MASK
			var rotation = tile_data & ROTATION_MASK
				
			if model in [NO_MODEL, RAMP_UPPER, RAMP_LOWER]:
				if terrain_data.is_navigable(x, y):
					ground_sts.append(navmesh_st)
			else:
				var mesh
				var tile = Vector2(1, 1)
				if model == CLIFF_CORNER_OUTER:
					mesh = outer_corner
					if rotation == ROT_0:
						tile = Vector2(0, 1)
					elif rotation == ROT_90:
						tile = Vector2(0, 0)
					elif rotation == ROT_180:
						tile = Vector2(4, 0)
					elif rotation == ROT_270:
						tile = Vector2(4, 1)
				elif model == CLIFF_CORNER_INNER:
					mesh = inner_corner
					if rotation == ROT_0:
						tile = Vector2(1, 1)
					elif rotation == ROT_90:
						tile = Vector2(1, 0)
					elif rotation == ROT_180:
						tile = Vector2(2, 0)
					elif rotation == ROT_270:
						tile = Vector2(2, 1)
				elif model == CLIFF_SIDE:
					mesh = side
					if rotation == ROT_0:
						tile = Vector2(3, 1)
					elif rotation == ROT_90:
						tile = Vector2(1, 2)
					elif rotation == ROT_180:
						tile = Vector2(3, 0)
					elif rotation == ROT_270:
						tile = Vector2(2, 2)
				elif model == RAMP_UPPER_LEFT:
					mesh = upper_left_ramp
					if rotation == ROT_0:
						tile = Vector2(1, 1)
					elif rotation == ROT_90:
						tile = Vector2(1, 0)
					elif rotation == ROT_180:
						tile = Vector2(2, 0)
					elif rotation == ROT_270:
						tile = Vector2(2, 1)
				elif model == RAMP_UPPER_RIGHT:
					mesh = upper_right_ramp
					if rotation == ROT_0:
						tile = Vector2(2, 1)
					elif rotation == ROT_90:
						tile = Vector2(1, 1)
					elif rotation == ROT_180:
						tile = Vector2(1, 0)
					elif rotation == ROT_270:
						tile = Vector2(2, 0)
				elif model == RAMP_LOWER_LEFT:
					mesh = lower_left_ramp
					if rotation == ROT_0:
						tile = Vector2(1, 2)
					elif rotation == ROT_90:
						tile = Vector2(3, 0)
					elif rotation == ROT_180:
						tile = Vector2(2, 2)
					elif rotation == ROT_270:
						tile = Vector2(3, 1)
				elif model == RAMP_LOWER_RIGHT:
					mesh = lower_right_ramp
					if rotation == ROT_0:
						tile = Vector2(2, 2)
					elif rotation == ROT_90:
						tile = Vector2(3, 1)
					elif rotation == ROT_180:
						tile = Vector2(1, 2)
					elif rotation == ROT_270:
						tile = Vector2(3, 0)
				else:
					mesh = BoxMesh.new()
					mesh.size = Vector3(0.6, 0.6, 0.6)
				# This is where we'd figure out what model to show
				var mesh_node = MeshInstance3D.new()
				mesh_node.mesh = mesh
				for idx in mesh_node.get_surface_override_material_count():
					if idx < cliff_material.size():
						mesh_node.set_surface_override_material(idx, cliff_material[idx])
				mesh_node.set_shader_instance_uniform("TilesetScaleX", 0.2)
				mesh_node.set_shader_instance_uniform("TilesetScaleY", 1.0/3.0)
				mesh_node.set_shader_instance_uniform("toff_x", tile.x)
				mesh_node.set_shader_instance_uniform("toff_y", tile.y)
				
				mesh_node.set_shader_instance_uniform("top_left", tl)
				mesh_node.set_shader_instance_uniform("top_right", tr)
				mesh_node.set_shader_instance_uniform("bottom_left", bl)
				mesh_node.set_shader_instance_uniform("bottom_right", br)
				
				mesh_node.translate(Vector3(x, 0, y))
				# These go down so that the rotations are clockwise
				if rotation == ROT_90:
					mesh_node.rotate(Vector3.DOWN, PI*0.5)
				elif rotation == ROT_180:
					mesh_node.rotate(Vector3.DOWN, PI)
				elif rotation == ROT_270:
					mesh_node.rotate(Vector3.DOWN, PI*1.5)
					
				mesh_instances.append(mesh_node)
				
				# Create physics mesh for cliffs
				# TODO: Remove unnecessary faces
				# TODO: Make the size of the collider represent the shape of the
				# cliff rather than cubes
				
				_create_quad_face(
					[physics_st],
					[
						Vector3(x-0.5, tl+cliff_level+1.0, y-0.5),
						Vector3(x+0.5, tr+cliff_level+1.0, y-0.5),
						Vector3(x+0.5, br+cliff_level+1.0, y+0.5),
						Vector3(x-0.5, bl+cliff_level+1.0, y+0.5)
					]
				)
				_create_quad_face(
					[physics_st],
					[
						Vector3(x+0.5, tr+cliff_level+1.0, y-0.5),
						Vector3(x-0.5, tl+cliff_level+1.0, y-0.5),
						Vector3(x-0.5, tl+cliff_level, y-0.5),
						Vector3(x+0.5, tr+cliff_level, y-0.5)
					]
				)
				_create_quad_face(
					[physics_st],
					[
						Vector3(x+0.5, br+cliff_level+1.0, y+0.5),
						Vector3(x+0.5, tr+cliff_level+1.0, y-0.5),
						Vector3(x+0.5, tr+cliff_level, y-0.5),
						Vector3(x+0.5, br+cliff_level, y+0.5)
					]
				)
				_create_quad_face(
					[physics_st],
					[
						Vector3(x-0.5, tl+cliff_level+1.0, y-0.5),
						Vector3(x-0.5, bl+cliff_level+1.0, y+0.5),
						Vector3(x-0.5, bl+cliff_level, y+0.5),
						Vector3(x-0.5, tl+cliff_level, y-0.5)
					]
				)
				_create_quad_face(
					[physics_st],
					[
						Vector3(x-0.5, bl+cliff_level+1.0, y+0.5),
						Vector3(x+0.5, br+cliff_level+1.0, y+0.5),
						Vector3(x+0.5, br+cliff_level, y+0.5),
						Vector3(x-0.5, bl+cliff_level, y+0.5)
					]
				)
			
			var offsets = ramp_offset(model, rotation)
			tl += offsets["tl"]
			tr += offsets["tr"]
			bl += offsets["bl"]
			br += offsets["br"]
			_create_quad_face(
				ground_sts,
				[
					Vector3(x-0.5, tl+cliff_level, y-0.5),
					Vector3(x+0.5, tr+cliff_level, y-0.5),
					Vector3(x+0.5, br+cliff_level, y+0.5),
					Vector3(x-0.5, bl+cliff_level, y+0.5)
				]
			)
	
	var mesh_node = MeshInstance3D.new()
	view_st.set_material(material)
	mesh_node.mesh = view_st.commit()
	mesh_node.set_shader_instance_uniform("TilesetScaleX", 0.2)
	mesh_node.set_shader_instance_uniform("TilesetScaleY", 1.0/3.0)
	mesh_node.set_shader_instance_uniform("toff_x", 4.0)
	mesh_node.set_shader_instance_uniform("toff_y", 2.0)
	mesh_instances.append(mesh_node)
	return {
		"mesh_instances": mesh_instances,
		"navmesh": navmesh_st.commit(),
		"physics": physics_st.commit(),
	}

static func _navmesh_from_mesh(mesh):
	# The built "NavigationMesh.create_from_mesh" is broken...
	var navmesh = NavigationMesh.new()
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	
	var verts = PackedVector3Array()
	var polygons = []
	
	for vert_idx in range(mdt.get_vertex_count()):
		verts.append(mdt.get_vertex(vert_idx))
		
	for face_idx in range(mdt.get_face_count()):
		polygons.append(
			PackedInt32Array([
				mdt.get_face_vertex(face_idx, 0),
				mdt.get_face_vertex(face_idx, 1),
				mdt.get_face_vertex(face_idx, 2),
			])
		)
	
	navmesh.set_vertices(verts)
	for polygon in polygons:
		navmesh.add_polygon(
			polygon
		)
	
	return navmesh

func _emit_physics_collider_input_events(
	camera: Node,
	event: InputEvent,
	pos: Vector3,
	normal: Vector3,
	_shape_idx: int
):
	emit_signal(
		"input_event",
		camera,
		event,
		pos,
		normal
	)

func _generate_pathfinding_nodes(terrain_data):
	var navigation_nodes = {}
	var navigation_connections = []

	for x in range(terrain_data.width):
		for y in range(terrain_data.height):
			var tile_data = terrain_data.get_data(x, y)
			var tl = terrain_data.get_terrain_height(x, y)
			var tr = terrain_data.get_terrain_height(x+1, y)
			var bl = terrain_data.get_terrain_height(x, y+1)
			var br = terrain_data.get_terrain_height(x+1, y+1)
			var cliff_level = tile_data & 0b111
			
			var navigation_node = NavigationNode3D.new()
			navigation_nodes[Vector3i(x, y, 0)] = navigation_node
			
			if terrain_data.is_navigable(x, y):
				navigation_node.disabled = false
			else:
				navigation_node.disabled = true
				
			if x > 0:
				navigation_connections.append(
					[
						navigation_node,
						navigation_nodes[Vector3i(x-1, y, 0)]
					]
				)
			if y > 0:
				navigation_connections.append(
					[
						navigation_node,
						navigation_nodes[Vector3i(x, y-1, 0)]
					]
				)
			if x > 0 and y > 0:
				var diagonal_navigation_node = NavigationNode3D.new()
				navigation_nodes[Vector3i(x, y, 1)] = diagonal_navigation_node
				diagonal_navigation_node.position = Vector3(x-0.5, cliff_level + tl, y-0.5)
				diagonal_navigation_node.disabled = true
				if (
					terrain_data.is_navigable(x, y)
					and terrain_data.is_navigable(x-1, y)
					and terrain_data.is_navigable(x-1, y-1)
					and terrain_data.is_navigable(x, y-1)
				):
					diagonal_navigation_node.disabled = false
				navigation_connections.append(
					[
						diagonal_navigation_node,
						navigation_nodes[Vector3i(x-1, y-1, 0)]
					]
				)
				navigation_connections.append(
					[
						diagonal_navigation_node,
						navigation_nodes[Vector3i(x, y, 0)]
					]
				)
				navigation_connections.append(
					[
						diagonal_navigation_node,
						navigation_nodes[Vector3i(x, y-1, 0)]
					]
				)
				navigation_connections.append(
					[
						diagonal_navigation_node,
						navigation_nodes[Vector3i(x-1, y, 0)]
					]
				)
				
			navigation_node.position = Vector3(x, cliff_level + (bl+tr)/2.0, y)
			var model = tile_data & MODEL_MASK
			if model == RAMP_UPPER:
				navigation_node.position.y += 0.75
			if model == RAMP_LOWER:
				navigation_node.position.y += 0.25

	return {
		"navigation_nodes": navigation_nodes,
		"navigation_connections": navigation_connections,
	}
	
	
func _regenerate_navigation():
	for child in _navigation_nodes.values():
		remove_child(child)
		child.queue_free()
		
	var pathfinding = _generate_pathfinding_nodes(terrain)
	_navigation_nodes = pathfinding["navigation_nodes"]
	for node in _navigation_nodes.values():
		add_child(node)
		
	for connection in pathfinding["navigation_connections"]:
		connection[0].connect_to(connection[1])


func _regenerate_mesh():
	for child in managed_children:
		remove_child(child)
		child.queue_free()

	managed_children = []
	notify_property_list_changed()

	if width > 0 and height > 0:
		var ret = generate_mesh(terrain)
		if not hide_decorative_layer:
			for mesh_node in ret["mesh_instances"]:
				add_child(mesh_node)
				managed_children.append(mesh_node)
	
		_regenerate_navigation()
	
		# Always generate a physics body in the editor so we can use it for
		# raycasts when editing the terrain.
		if generate_static_physics_body or Engine.is_editor_hint():
			var physics_mesh_node = MeshInstance3D.new()
			physics_mesh_node.name = "RtsTerrainPhysicsMesh"
			physics_mesh_node.mesh = ret["physics"]
			add_child(physics_mesh_node)
			managed_children.append(physics_mesh_node)

			# The docs say this is "mainly used for testing"...
			physics_mesh_node.create_trimesh_collision()
			if physics_mesh_node.get_child_count() > 0:
				physics_mesh_node.get_children()[0].name = "RtsTerrainPhysicsBody"
				physics_mesh_node.get_children()[0].add_to_group("terrain_collider")
				physics_mesh_node.get_children()[0].connect("input_event", _emit_physics_collider_input_events)
				
			# Now remove the mesh (since we didn't really want to show it in the first place)
			if not debug_draw_collider:
				physics_mesh_node.mesh = null
		
		if generate_navigation_region:
			var nav_region = NavigationRegion3D.new()
			nav_region.navmesh = _navmesh_from_mesh(ret["navmesh"])
			add_child(nav_region)
			managed_children.append(nav_region)
			
		if debug_draw_navigation:
			var navmesh_node = MeshInstance3D.new()
			navmesh_node.mesh = ret["navmesh"]
			add_child(navmesh_node)
			managed_children.append(navmesh_node)

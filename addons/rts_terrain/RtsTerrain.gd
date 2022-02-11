@tool
class_name RtsTerrain
extends Node3D

const RAMP = -1

@export var generate_navigation_region: bool = true
@export var generate_static_physics_body: bool = true
@export var navigation_region_debug: bool = false:
	get:
		return navigation_region_debug
	set(v):
		navigation_region_debug = v
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
			
@export var terrain_holes: PackedInt32Array:
	get:
		return terrain.holes
	set(v):
		if v.size() != width * height:
			print("new terrain of size ", v.size(), " doesn't match size: ", width*height)
		else:
			terrain.holes = v
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
	_regenerate_mesh()
	
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
	st: SurfaceTool,
	points: Array
):
	assert(points.size() == 3)
	var normal = (points[0] - points[1]).cross(points[2] - points[0]).normalized()
	var uv = Vector2(0, 0)
	
	for point in [
		points[0], points[1], points[2],
	]:
		st.set_normal(normal)
		st.set_uv(uv)
		st.add_vertex(point)


static func _create_quad_face(
	st: SurfaceTool,
	points: Array
):
	assert(points.size() == 4)
	_create_tri_face(st, [points[0], points[1], points[3]])
	_create_tri_face(st, [points[1], points[2], points[3]])


static func _create_square(
	st: SurfaceTool,
	center: Vector3,
	size: float,
	rot: Vector3,
	vscale: float = 1.0
):
	var half_size = size*0.5
	var new_basis = Basis.from_euler(rot).scaled(Vector3(1.0, vscale, 1.0))
	var xform = Transform3D(new_basis, center)
	_create_quad_face(
		st,
		[
			xform * Vector3(-half_size, 0, -half_size),
			xform * Vector3(half_size, 0, -half_size),
			xform * Vector3(half_size, 0, half_size),
			xform * Vector3(-half_size, 0, half_size)
		]
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


enum RampShape {
	TO_UP,
	TO_DOWN,
	TO_LEFT,
	TO_RIGHT,
	TO_TOPLEFT,
	TO_TOPRIGHT,
	TO_BOTTOMLEFT,
	TO_BOTTOMRIGHT,
	ERROR
}

static func ramp_dir(
	up,
	down,
	left,
	right
):
	var highest = max(up, down, left, right)
	
	up = int(up == highest)
	down = int(down == highest)
	left = int(left == highest)
	right = int(right == highest)
	
	match [up, down, left, right]:
		[1, 0, 0, 0]:
			return RampShape.TO_UP
		[1, 0, 1, 1]:
			return RampShape.TO_UP
		[0, 1, 0, 0]:
			return RampShape.TO_DOWN
		[0, 1, 1, 1]:
			return RampShape.TO_DOWN
		[0, 0, 1, 0]:
			return RampShape.TO_LEFT
		[1, 1, 1, 0]:
			return RampShape.TO_LEFT
		[0, 0, 0, 1]:
			return RampShape.TO_RIGHT
		[1, 1, 0, 1]:
			return RampShape.TO_RIGHT
		[1, 0, 1, 0]:
			return RampShape.TO_TOPLEFT
		[1, 0, 0, 1]:
			return RampShape.TO_TOPRIGHT
		[0, 1, 1, 0]:
			return RampShape.TO_BOTTOMLEFT
		[0, 1, 0, 1]:
			return RampShape.TO_BOTTOMRIGHT
		[1, 1, 1, 1]:
			# It's flat, we shouldn't need a ramp
			return RampShape.ERROR
		[0, 0, 0, 0]:
			# It's flat, we shouldn't need a ramp
			return RampShape.ERROR
		[1, 1, 0 ,0]:
			# How do you have a ramp go both ways?
			return RampShape.ERROR
		[0, 0, 1, 1]:
			# How do you have a ramp go both ways?
			return RampShape.ERROR
	
	print("Could not match: ", up, down, left, right)
	return RampShape.ERROR

static func generate_mesh(terrain_data, navmesh=false):
	var st = SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(terrain_data.width):
		for y in range(terrain_data.height):
			var cliff_level = terrain_data.get_cliff_level(x, y)
			var up_level = terrain_data.get_cliff_level(x, y-1)
			var down_level = terrain_data.get_cliff_level(x, y+1)
			var left_level = terrain_data.get_cliff_level(x-1, y)
			var right_level = terrain_data.get_cliff_level(x+1, y)
			
			var tl = terrain_data.get_terrain_height(x, y)
			var tr = terrain_data.get_terrain_height(x+1, y)
			var bl = terrain_data.get_terrain_height(x, y+1)
			var br = terrain_data.get_terrain_height(x+1, y+1)
			
			if terrain_data.is_hole(x, y) and navmesh:
				continue
			
			if cliff_level == RAMP:
				var shape = ramp_dir(up_level, down_level, left_level, right_level)
				match shape:
					RampShape.TO_RIGHT:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,-PI/2,0)),
							Vector3(x, 0, y),
						)
						_create_ramp(
							st,
							xform,
							navmesh or up_level == RAMP or up_level == right_level,
							navmesh or down_level == RAMP or down_level == right_level,
						)
					RampShape.TO_LEFT:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,PI/2,0)),
							Vector3(x, 0, y),
						)
						_create_ramp(
							st,
							xform,
							navmesh or down_level == RAMP or down_level == left_level,
							navmesh or up_level == RAMP or up_level == left_level
						)
					RampShape.TO_UP:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,0,0)),
							Vector3(x, 0, y),
						)
						_create_ramp(
							st,
							xform,
							navmesh or left_level == RAMP or left_level == up_level,
							navmesh or right_level == RAMP or right_level == up_level,
						)
					RampShape.TO_DOWN:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,PI,0)),
							Vector3(x, 0, y),
						)
						_create_ramp(
							st,
							xform,
							navmesh or right_level == RAMP or right_level == down_level,
							navmesh or left_level == RAMP or left_level == down_level
						)
					RampShape.TO_TOPLEFT:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,0,0)),
							Vector3(x, 0, y),
						)
						_create_ramp_corner(
							st,
							xform,
							navmesh or down_level == RAMP,
							navmesh or right_level == RAMP,
						)
					RampShape.TO_TOPRIGHT:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,-PI/2,0)),
							Vector3(x, 0, y),
						)
						_create_ramp_corner(
							st,
							xform,
							navmesh or left_level == RAMP,
							navmesh or down_level == RAMP,
						)
					RampShape.TO_BOTTOMRIGHT:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,PI,0)),
							Vector3(x, 0, y),
						)
						_create_ramp_corner(
							st,
							xform,
							navmesh or up_level == RAMP,
							navmesh or left_level == RAMP,
						)
					RampShape.TO_BOTTOMLEFT:
						var xform = Transform3D(
							Basis.from_euler(Vector3(0,PI/2,0)),
							Vector3(x, 0, y),
						)
						_create_ramp_corner(
							st,
							xform,
							navmesh or right_level == RAMP,
							navmesh or up_level == RAMP,
						)
					RampShape.ERROR:
						_create_square(
							st,
							Vector3(x, 0.5, y),
							1.0,
							Vector3(0, 0, 0)
						)
			else:
				_create_quad_face(
					st,
					[
						Vector3(x-0.5, tl+cliff_level, y-0.5),
						Vector3(x+0.5, tr+cliff_level, y-0.5),
						Vector3(x+0.5, br+cliff_level, y+0.5),
						Vector3(x-0.5, bl+cliff_level, y+0.5)
					]
				)
				
				if not navmesh:
					if cliff_level > up_level:
						_create_quad_face(
							st,
							[
								Vector3(x+0.5, tr+cliff_level, y-0.5),
								Vector3(x-0.5, tl+cliff_level, y-0.5),
								Vector3(x-0.5, tl+up_level, y-0.5),
								Vector3(x+0.5, tr+up_level, y-0.5)
							]
						)
					if cliff_level > down_level:
						_create_quad_face(
							st,
							[
								Vector3(x-0.5, bl+cliff_level, y+0.5),
								Vector3(x+0.5, br+cliff_level, y+0.5),
								Vector3(x+0.5, br+down_level, y+0.5),
								Vector3(x-0.5, bl+down_level, y+0.5)
							]
						)
					if cliff_level > left_level:
						_create_quad_face(
							st,
							[
								Vector3(x-0.5, tl+cliff_level, y-0.5),
								Vector3(x-0.5, bl+cliff_level, y+0.5),
								Vector3(x-0.5, bl+left_level, y+0.5),
								Vector3(x-0.5, tl+left_level, y-0.5)
							]
						)
					if cliff_level > right_level:
						_create_quad_face(
							st,
							[
								Vector3(x+0.5, br+cliff_level, y+0.5),
								Vector3(x+0.5, tr+cliff_level, y-0.5),
								Vector3(x+0.5, tr+right_level, y-0.5),
								Vector3(x+0.5, br+right_level, y+0.5)
							]
						)

	return st.commit()

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

func _regenerate_mesh():
	for child in managed_children:
		remove_child(child)
		child.queue_free()

	managed_children = []
	notify_property_list_changed()

	if width > 0 and height > 0:
		var mesh = MeshInstance3D.new()
		mesh.mesh = generate_mesh(terrain, navigation_region_debug)
		add_child(mesh)
		managed_children.append(mesh)
	
		# Always generate a physics body in the editor so we can use it for
		# raycasts when editing the terrain.
		if generate_static_physics_body or Engine.is_editor_hint():
			# The docs say this is "mainly used for testing"...
			mesh.create_trimesh_collision()

			var static_body = mesh.get_children()[0]
			static_body.connect("input_event", _emit_physics_collider_input_events)
		
		if generate_navigation_region:
			var nav_region = NavigationRegion3D.new()
			nav_region.navmesh = _navmesh_from_mesh(generate_mesh(terrain, true))
			add_child(nav_region)
			managed_children.append(nav_region)

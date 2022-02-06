@tool
extends Node3D

const RAMP = -1

@export var generate_navigation_region: bool = true

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
	var normal = (points[0] - points[1]).cross(points[2] - points[0]).normalized()
	var uv = Vector2(0, 0)
	
	for point in [
		points[0], points[1], points[3],
		points[1], points[2], points[3]
	]:
		st.set_normal(normal)
		st.set_uv(uv)
		st.add_vertex(point)


static func _create_square(
	st: SurfaceTool,
	center: Vector3,
	size: float,
	rotation: Vector3
):
	var half_size = size*0.5
	var basis = Basis.from_euler(rotation)
	var xform = Transform3D(basis, center)
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
	var width
	var height
	var data
	
	func get(x, y):
		if x < 0 or width <= x:
			return 0
		if y < 0 or height <= y:
			return 0

		var idx = x + y*width
		return data[idx]

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

static func generate_mesh(navmesh=false):
	print("regenerating mesh")
	var st = SurfaceTool.new()

	var terrain = TerrainData.new()
	terrain.width = 8
	terrain.height = 10
	terrain.data = [
		0,  0, 0, 0, 0, 0, 0, 0,
		0,  0, 0, 0, 0, 0, 0, 0,
		0,  0, 0, 0, 0, 0, 0, 0,
		0,  0,-1,-1, 0, 0, 0, 0,
		-1, 1, 1, 1,-1, 0, 0, 0,
		-1, 1, 1, 1,-1, 0, 0, 0,
		0,  0,-1,-1, 0, 0, 0, 0,
		0,  0, 0, 0, 0, 0, 0, 0,
		0,  0, 0, 0, 0, 0, 0, 0,
		0,  0, 0, 0, 0, 0, 0, 0,
	]

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(terrain.width):
		for y in range(terrain.height):
			var cliff_level = terrain.get(x, y)
			var up_level = terrain.get(x, y-1)
			var down_level = terrain.get(x, y+1)
			var left_level = terrain.get(x-1, y)
			var right_level = terrain.get(x+1, y)
			
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
				_create_square(
					st,
					Vector3(x, cliff_level, y),
					1.0,
					Vector3(0, 0, 0)
				)
				
				if not navmesh:
					if up_level != RAMP:
						if cliff_level > up_level:
							_create_square(
								st,
								Vector3(x, float(cliff_level+up_level)/2, y-0.5),
								1.0,
								Vector3(-PI/2, 0, 0)
							)
					if down_level != RAMP:
						if cliff_level > down_level:
							_create_square(
								st,
								Vector3(x, float(cliff_level+down_level)/2, y+0.5),
								1.0,
								Vector3(PI/2, 0, 0)
							)
					if left_level != RAMP:
						if cliff_level > left_level:
							_create_square(
								st,
								Vector3(x-0.5, float(cliff_level+left_level)/2, y),
								1.0,
								Vector3(0, 0, PI/2)
							)
					if right_level != RAMP:
						if cliff_level > right_level:
							_create_square(
								st,
								Vector3(x+0.5, float(cliff_level+right_level)/2, y),
								1.0,
								Vector3(0, 0, -PI/2)
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

func _regenerate_mesh():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var mesh = MeshInstance3D.new()
	mesh.mesh = generate_mesh()
	add_child(mesh)
	
	if generate_navigation_region:
		var nav_region = NavigationRegion3D.new()
		nav_region.navmesh = _navmesh_from_mesh(generate_mesh(true))
		add_child(nav_region)

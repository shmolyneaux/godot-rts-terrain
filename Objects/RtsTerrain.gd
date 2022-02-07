@tool
extends MeshInstance3D

const RAMP_SENTINEL = -1

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

func _create_cliff(
	st: SurfaceTool,
	position: Vector3,
	tl: bool,
	tr: bool,
	bl: bool,
	br: bool
):
	var size = 1.0
	var half_size = size*0.5
	
	# Create the horizontal faces
	for point in [
		position + Vector3(-half_size, size*int(tl), -half_size),
		position + Vector3(half_size, size*int(tr), -half_size),
		position + Vector3(-half_size, size*int(bl), half_size),
		position + Vector3(half_size, size*int(br), half_size),
	]:
		_create_square(
			st,
			point,
			size,
			Vector3(0, 0, 0)
		)
	
	# Create the vertical faces
	if tl != tr:
		var center = position + Vector3(0, half_size, -half_size)
		var rot = Vector3(0, 0, (int(tr)-int(tl))*PI/2)
		_create_square(
			st,
			center,
			size,
			rot
		)
	if tl != bl:
		var center = position + Vector3(-half_size, half_size, 0)
		var rot = Vector3((int(tl)-int(bl))*PI/2, 0, 0)
		_create_square(
			st,
			center,
			size,
			rot
		)
	if tr != br:
		var center = position + Vector3(half_size, half_size, 0)
		var rot = Vector3((int(tr)-int(br))*PI/2, 0, 0)
		_create_square(
			st,
			center,
			size,
			rot
		)
	if bl != br:
		var center = position + Vector3(0, half_size, half_size)
		var rot = Vector3(0, 0, (int(br)-int(bl))*PI/2)
		_create_square(
			st,
			center,
			size,
			rot
		)

func _enter_tree():
	_regenerate_mesh()

class TerrainData:
	var width
	var height
	var data
	
	func get(x, y):
		var idx = x + y*width
		if idx < data.size():
			return data[idx]
		return 0

func _regenerate_mesh():
	var st = SurfaceTool.new()

	var terrain = TerrainData.new()
	terrain.width = 6
	terrain.height = 8
	terrain.data = [
		1, 1, 1, 1, 1, 1,
		0, 0, 0, 0, 1, 1,
		0, 0, 0, 1, 1, 1,
		1, 0, 0, 1, 1, 1,
		1, 0, 0, 0, 0, 1,
		0, 0, 0, 1, 0, 1,
		0, 0, 0, 1, 1, 1,
		0, 0, 0, 1, 1, 1,
	]

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in range(terrain.width):
		for y in range(terrain.height):
			var tl = terrain.get(x,   y)
			var tr = terrain.get(x+1, y)
			var bl = terrain.get(x,   y+1)
			var br = terrain.get(x+1, y+1)
			
			_create_cliff(
				st,
				Vector3(x, 0, y),
				tl,
				tr,
				bl,
				br
			)

	mesh = st.commit()

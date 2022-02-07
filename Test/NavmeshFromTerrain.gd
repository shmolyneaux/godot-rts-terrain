extends NavigationRegion3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var new_navmesh = NavigationMesh.new()
	var terrain_mesh = get_parent().get_node("RtsTerrain").get_children()[0].mesh
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(terrain_mesh, 0)
	
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
	print(navmesh.get_polygon_count())
	#navmesh.create_from_mesh(terrain_mesh)
	#print(navmesh.get_polygon_count())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

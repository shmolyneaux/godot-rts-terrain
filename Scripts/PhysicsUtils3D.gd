extends Object
class_name PhysicsUtils3D

## Must be called from _physics_process
static func intersect_camera_frustum(
	camera: Camera3D,
	corner_a: Vector2,
	corner_b: Vector2,
	distance: float=100.0,
	max_results: int=32,
):
	var min_x = min(corner_a.x, corner_b.x)
	var max_x = max(corner_a.x, corner_b.x)
	var min_y = min(corner_a.y, corner_b.y)
	var max_y = max(corner_a.y, corner_b.y)
	
	var screen_coords = [
		Vector2(min_x, min_y),
		Vector2(max_x, min_y),
		Vector2(max_x, max_y),
		Vector2(min_x, max_y),
	]

	var points = []
	for screen_coord in screen_coords:
		points.append(camera.project_ray_origin(screen_coord))
		points.append(camera.project_ray_origin(screen_coord)+camera.project_ray_normal(screen_coord)*distance)
	
	var shape = ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array(points)
	var physics_query_params = PhysicsShapeQueryParameters3D.new()
	physics_query_params.shape = shape
	physics_query_params.collide_with_areas = true
	
	var space_state = camera.get_world_3d().direct_space_state
	return space_state.intersect_shape(physics_query_params, max_results)

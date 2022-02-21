extends Node3D

var target_location = null
var speed = 5.0

var distance_along_path = 0.0
var path = []:
	get:
		return path
	set(new_path):
		path = new_path
		distance_along_path = 0.0
		if not path.size():
			return
		
		# This node's current position
		var current_position = global_transform.origin
		
		# The point along the path that's closest to the current node
		var closest_point = path[0]
		
		# The value we'll assign to distance_along_path for the current closest_point
		var distance_along_path_to_closest_point = 0.0
		
		# Squared distance from current_position to closest point, so that we
		# can easily check if some new point is better/worse
		var distance2_to_closest_point = current_position.distance_squared_to(closest_point)
		
		# The distance we've along the path so far for computing distance_along_path_to_closest_point
		var distance_so_far = 0.0
		
		for idx in range(1, path.size()):
			var candidate_position = Geometry3D.get_closest_point_to_segment(
				current_position,
				path[idx],
				path[idx-1]
			)
			var candidate_distance2 = current_position.distance_squared_to(candidate_position)
			if candidate_distance2 < distance2_to_closest_point:
				closest_point = candidate_position
				distance2_to_closest_point = candidate_distance2
				distance_along_path_to_closest_point = distance_so_far + path[idx-1].distance_to(closest_point)
			
			distance_so_far += path[idx].distance_to(path[idx-1])
		
		distance_along_path = distance_along_path_to_closest_point

@export var total_health = 10.0
@export var health: float = total_health:
	get:
		return health
	set(v):
		health = v
		$health_bar.fill_ratio = health/total_health
		if health <= 0:
			queue_free()


# Called when the node enters the scene tree for the first time.
func _ready():
	target_location = get_parent().get_node("Walk Target").global_transform.origin
	NavigationRouter.register_destination(
		self,
		target_location,
		_update_path
	)


# TODO: how do you just get the setter?
func _update_path(new_path):
	path = new_path


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	distance_along_path += speed*delta
	
	# Now figure out where that distance is on the path
	var d = 0.0
	if path.size() == 0:
		return

	var pos = path[0]
	for point in path:
		var segment = point - pos
		var segment_length = segment.length()
		if d + segment_length < distance_along_path:
			d += segment_length
		else:
			pos = pos + segment.normalized() * (distance_along_path - d)
			break
		pos = point
		
	position = pos
	if target_location.distance_to(global_transform.origin) < 1.0:
		queue_free()

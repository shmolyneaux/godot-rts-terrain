extends Node3D

var target_location = null
var speed = 5.0
var path
var distance_along_path = 0.0

@onready var target_debug_ball = $Target

# Called when the node enters the scene tree for the first time.
func _ready():
	# TODO: start with astar.get_closest_position_in_segment 
	var closest_point = NodeNavigationServer3D.astar.get_closest_point(global_transform.origin)
	target_location = get_parent().get_node("Walk Target").global_transform.origin
	var target_point = NodeNavigationServer3D.astar.get_closest_point(target_location)
	path = NodeNavigationServer3D.astar.get_point_path(closest_point, target_point)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	distance_along_path += speed*delta
	
	# Now figure out where that distance is on the path
	var d = 0.0
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

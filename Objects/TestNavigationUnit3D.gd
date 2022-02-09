extends Node3D

var target_location = null
var speed = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	target_location = get_parent().get_node("Walk Target").global_transform.origin
	$NavigationAgent3D.set_target_location(target_location)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	speed = 5
	var potential_new_target = get_parent().get_node("Walk Target").global_transform.origin
	if target_location != potential_new_target:
		print("changing target")
		target_location = potential_new_target
		$NavigationAgent3D.set_target_location(target_location)

	if not $NavigationAgent3D.is_target_reached():
		var move_target = $NavigationAgent3D.get_next_location()
		var move_vec = (move_target - position).normalized() * speed * delta

		# Don't bounce around the target location, snap to it exactly if it's close
		#print(move_target, " =?= " , target_location, " =?= ", position)
		if (move_target - position).length() < move_vec.length():
			position = move_target
		else:
			position = position + move_vec

	if target_location.distance_to(global_transform.origin) < 1.0:
		queue_free()

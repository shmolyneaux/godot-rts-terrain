extends Sprite2D

var target_location = null
var speed = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	target_location = get_parent().get_node("Walk Target").global_position
	$NavigationAgent2D.set_target_location(target_location)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var potential_new_target = get_viewport().get_mouse_position()
	if target_location != potential_new_target:
		target_location = potential_new_target
		$NavigationAgent2D.set_target_location(target_location)
		
	if not $NavigationAgent2D.is_target_reached():
		var move_target = $NavigationAgent2D.get_next_location()
		var move_vec = (move_target - position).normalized() * speed * delta
		
		# Don't bounce around the target location, snap to it exactly if it's close
		print(move_target, " =?= " , target_location, " =?= ", position)
		if (move_target - position).length() < move_vec.length():
			position = move_target
		else:
			position = position + move_vec
			position = move_target

extends Camera3D

@export var speed: float = 5

@onready var target = $"Target Camera Position"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var move_vec = Vector3()
	if Input.is_action_pressed("move_north"):
		move_vec.z -= 1
	if Input.is_action_pressed("move_south"):
		move_vec.z += 1
	if Input.is_action_pressed("move_west"):
		move_vec.x -= 1
	if Input.is_action_pressed("move_east"):
		move_vec.x += 1
	if Input.is_action_pressed("move_down"):
		move_vec.y -= 1
	if Input.is_action_pressed("move_up"):
		move_vec.y += 1

	if move_vec.length() != 0:
		move_vec = move_vec.normalized() * speed * delta
		var new_position = target.global_transform.origin + move_vec
		new_position.x = clamp(new_position.x, 4, 16)
		new_position.y = clamp(new_position.y, 4, 14)
		new_position.z = clamp(new_position.z, 4, 18)
		target.global_transform.origin = new_position

	global_transform.origin = global_transform.origin.lerp(target.global_transform.origin, 0.5)

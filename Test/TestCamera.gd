extends Camera3D

@export var speed: float = 5

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
		global_transform.origin += move_vec

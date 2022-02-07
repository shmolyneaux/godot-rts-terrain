@tool
extends Decal

@export var target: NodePath
@export var target_radius: float = 1.0:
	get:
		return target_radius
	set(radius):
		target_radius = radius
		extents.x = radius
		extents.z = radius

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target:
		var node = get_node(target)
		if node:
			global_transform.origin = node.global_transform.origin
			visible = true
		else:
			visible = false

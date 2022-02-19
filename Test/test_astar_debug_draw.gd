extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	NodeNavigationServer3D.connect_nodes($node_1, $node_2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

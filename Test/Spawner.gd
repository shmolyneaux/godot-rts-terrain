extends MeshInstance3D

@export var scene = preload("res://Test/TestUnit3D.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_timer_timeout():
	var unit = scene.instantiate()
	get_parent().add_child(unit)
	unit.global_transform = global_transform

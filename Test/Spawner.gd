extends MeshInstance3D

@export var scene = preload("res://Test/TestUnit3D.tscn")

func _on_timer_timeout():
	var unit = scene.instantiate()
	unit.transform = transform
	get_parent().add_child(unit)

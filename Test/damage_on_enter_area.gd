extends Area3D

var _damaging = false

func start_damage():
	_damaging = true
	
func stop_damage():
	_damaging = false

func _physics_process(delta):
	if _damaging:
		var areas = get_overlapping_areas()
		for unit in areas:
			unit.health -= 15.0*delta

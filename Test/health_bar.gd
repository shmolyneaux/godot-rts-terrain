extends MeshInstance3D

@export var fill_ratio: float = 1.0:
	get:
		return fill_ratio
	set(v):
		fill_ratio = v
		set_shader_instance_uniform("fill_ratio", v)

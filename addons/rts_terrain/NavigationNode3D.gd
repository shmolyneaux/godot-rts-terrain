extends Node3D
class_name NavigationNode3D

@export var disabled: bool = false:
	get:
		return disabled
	set(v):
		disabled = v
		if is_inside_tree():
			NodeNavigationServer3D.node_enabled(self, not v)

var _connection_queue = []

func connect_to(other: NavigationNode3D):
	if is_inside_tree():
		NodeNavigationServer3D.connect_nodes(self, other)
	else:
		_connection_queue.append(other)


func _notification(what):
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			NodeNavigationServer3D.node_moved(self, global_transform.origin)
		NOTIFICATION_ENTER_TREE:
			NodeNavigationServer3D.add_node(self)
			set_notify_transform(true)
			for other in _connection_queue:
				NodeNavigationServer3D.connect_nodes(self, other)
			_connection_queue = []
		NOTIFICATION_EXIT_TREE:
			NodeNavigationServer3D.remove_node(self)

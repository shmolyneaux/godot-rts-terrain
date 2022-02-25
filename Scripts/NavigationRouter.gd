extends Node
## Leverages the NodeNavigationServer3D to help entities path through the current
## scene and respond to changes in node connectivity.

# Caching is needed since the built-in AStar doesn't do caching
var _path_cache = {}
var _registered_nodes = {}


func _ready():
	NodeNavigationServer3D.navigation_updated.connect(_navigation_updated)


## Register a node's desire to path to a particular destination. `update_handler`
## will be called with a new path as needed to respond to changes in the navigation
## path.
##
## The path comes from NodeNavigationServer3D, and it contains the navigation node
## closest to the registering Node3D.
##
## For the sake of efficiency, the path may not start from the position of the
## provided node. Lastly, the returned path should not be mutated.
##
## The `update_handler` will be freed automatically when the node leaves the tree.
func register_destination(node: Node3D, target_position: Vector3, update_handler: Callable) -> void:
	_registered_nodes[node] = {
		"update_handler": update_handler,
		"target_position": target_position
	}
	update_handler.call(get_navigation_path(node, target_position))


func get_navigation_path(node: Node3D, target_position: Vector3) -> PackedVector3Array:
	var closest_id = NodeNavigationServer3D.astar.get_closest_point(node.global_transform.origin)
	var target_id = NodeNavigationServer3D.astar.get_closest_point(target_position)
	
	# Fast-return if we've already computed this
	var idx = Vector2i(closest_id, target_id)
	if idx in _path_cache:
		return _path_cache[idx]
	
	# Compute the path
	var path_ids = NodeNavigationServer3D.astar.get_id_path(closest_id, target_id)
	# TODO: is get_point_path 100% going to give the same result back?
	var path = PackedVector3Array()
	for id in path_ids:
		path.append(NodeNavigationServer3D.astar.get_point_position(id))
	
	# Update the cache
	# TODO: if `path` is a reference, then we don't need to do this as a separate
	# iteration over the path_ids.
	for id in path_ids:
		# Always replace things in the cache. The `path` we have is either
		# longer or coming from a different location. Using copies of this path
		# will let the shorter paths get freed sooner.
		_path_cache[Vector2i(id, target_id)] = path

	return path


func _navigation_updated():
	_path_cache = {}
	var nodes = _registered_nodes.keys()
	
	# For TD games, the newest nodes are likely to be further away from their
	# target than older nodes. Since Godot dicts preserve insertion order, we
	# want to access the nodes in reverse order so that we start with the newest
	# nodes. That should give us a better cache hit rate.
	for idx in range(nodes.size()-1, -1, -1):
		var node = nodes[idx]
		if not is_instance_valid(node):
			_registered_nodes.erase(node)
			continue
		var path = get_navigation_path(node, _registered_nodes[node].target_position)
		_registered_nodes[node].update_handler.call(path)

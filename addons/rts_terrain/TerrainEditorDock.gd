@tool
extends VBoxContainer

enum TerrainTool {
	RAISE_CLIFF=0,
	LOWER_CLIFF=1,
	CREATE_RAMP=2,
	REMOVE_RAMP=3,
	RAISE_TERRAIN=4,
	LOWER_TERRAIN=5,
	SMOOTH_TERRAIN=6,
}

signal tool_changed(tool: TerrainTool)


func _on_raise_cliff_pressed():
	print("emitting tool changed raised cliff")
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)


func _on_lower_cliff_pressed():
	print("emitting tool changed lower cliff")
	emit_signal("tool_changed", TerrainTool.LOWER_CLIFF)


func _on_create_ramp_pressed():
	print("emitting tool changed CREATE_RAMP")
	emit_signal("tool_changed", TerrainTool.CREATE_RAMP)


func _on_remove_ramp_pressed():
	print("emitting tool changed REMOVE_RAMP")
	emit_signal("tool_changed", TerrainTool.REMOVE_RAMP)


func _on_raise_terrain_pressed():
	print("emitting tool changed RAISE_TERRAIN")
	emit_signal("tool_changed", TerrainTool.RAISE_TERRAIN)


func _on_lower_terrain_pressed():
	print("emitting tool changed LOWER_TERRAIN")
	emit_signal("tool_changed", TerrainTool.LOWER_TERRAIN)


func _on_smooth_terrain_pressed():
	print("emitting tool changed SMOOTH_TERRAIN")
	emit_signal("tool_changed", TerrainTool.SMOOTH_TERRAIN)

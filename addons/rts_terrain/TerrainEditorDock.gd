@tool
extends VBoxContainer

enum TerrainTool {RAISE_CLIFF=0, LOWER_CLIFF=1, CREATE_RAMP=2, REMOVE_RAMP=3}

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

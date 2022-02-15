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

var data_value:
	get:
		return data_value
	set(v):
		var txt = ""
		var mask_bit = 1 << 31
		while mask_bit:
			if mask_bit & v:
				txt += "1"
			else:
				txt += "0"
			if mask_bit in [1<<8, 1<<16, 1<<24]:
				txt += "\n"
			mask_bit = mask_bit >> 1
		$data_container/data_value.text = txt
		data_value = v
		
		$"Cliff Level/Lower Cliff".disabled = data_value & RtsTerrain.CLIFF_LEVEL_MASK == 0
		$"Cliff Level/Raise Cliff".disabled = data_value & RtsTerrain.CLIFF_LEVEL_MASK == RtsTerrain.CLIFF_LEVEL_MASK

func _ready():
	data_value = 0

func _on_raise_cliff_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	if data_value & RtsTerrain.CLIFF_LEVEL_MASK != RtsTerrain.CLIFF_LEVEL_MASK:
		data_value = data_value + 1

func _on_lower_cliff_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	if data_value & RtsTerrain.CLIFF_LEVEL_MASK > 0:
		data_value = data_value - 1

func _on_raise_terrain_pressed():
	print("emitting tool changed RAISE_TERRAIN")
	emit_signal("tool_changed", TerrainTool.RAISE_TERRAIN)


func _on_lower_terrain_pressed():
	print("emitting tool changed LOWER_TERRAIN")
	emit_signal("tool_changed", TerrainTool.LOWER_TERRAIN)


func _on_smooth_terrain_pressed():
	print("emitting tool changed SMOOTH_TERRAIN")
	emit_signal("tool_changed", TerrainTool.SMOOTH_TERRAIN)


func _on_rot_0_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.ROTATION_MASK)) + RtsTerrain.ROT_0


func _on_rot_90_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.ROTATION_MASK)) + RtsTerrain.ROT_90


func _on_rot_180_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.ROTATION_MASK)) + RtsTerrain.ROT_180


func _on_rot_270_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.ROTATION_MASK)) + RtsTerrain.ROT_270


func _on_ul_ramp_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.RAMP_UPPER_LEFT


func _on_um_ramp_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.RAMP_UPPER


func _on_ur_ramp_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.RAMP_UPPER_RIGHT


func _on_ll_ramp_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.RAMP_LOWER_LEFT


func _on_lm_ramp_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.RAMP_LOWER


func _on_lr_ramp_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.RAMP_LOWER_RIGHT


func _on_side_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.CLIFF_SIDE


func _on_clear_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.NO_MODEL


func _on_outer_corner_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.CLIFF_CORNER_OUTER


func _on_inner_corner_pressed():
	emit_signal("tool_changed", TerrainTool.RAISE_CLIFF)
	data_value = (data_value & (~RtsTerrain.MODEL_MASK)) + RtsTerrain.CLIFF_CORNER_INNER

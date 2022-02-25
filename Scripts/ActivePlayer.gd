extends Node

signal gold_changed(int)
signal mode_changed(int)

enum {
	NORMAL_MODE,
	BUILD_MODE,
}

var mode: int = NORMAL_MODE:
	get:
		return mode
	set(new_mode):
		mode = new_mode
		mode_changed.emit(new_mode)


var gold: int = 0:
	get:
		return gold
	set(new_gold_amount):
		# This can go negative, but that doesn't _really_ matter for practical
		# purposes. That's better than crashing.
		gold = new_gold_amount
		gold_changed.emit(new_gold_amount)


func attempt_deduct_gold(amount):
	if gold >= amount:
		gold -= amount
		return true
	
	var stream_player = AudioStreamPlayer.new()
	stream_player.stream = 	preload("res://Assets/SFX/need_more_gold.wav")
	add_child(stream_player)
	stream_player.play()
	stream_player.finished.connect(func(): stream_player.queue_free())

extends Label


func _ready():
	update_label(ActivePlayer.gold)
	ActivePlayer.gold_changed.connect(update_label)


func update_label(new_amount: int):
	text = str(new_amount)

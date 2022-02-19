extends Button


func _on_debug_draw_navigation_pressed():
	NodeNavigationServer3D.debug_draw = not NodeNavigationServer3D.debug_draw

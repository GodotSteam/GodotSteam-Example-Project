extends Panel
#################################################
# MAIN MENU SCENE
#################################################


# Load up an example with the corresponding menu button
func _button_select_example_pressed(which: String) -> void:
	print("Loading up " + str(which) + " example")
	Loading.load_scene.emit(which)


func _on_exit_pressed() -> void:
	get_tree().quit()

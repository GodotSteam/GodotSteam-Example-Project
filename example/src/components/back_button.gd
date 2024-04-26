extends Button


func _on_back_pressed() -> void:
	Loading.load_scene.emit("main")

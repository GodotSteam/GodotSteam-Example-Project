extends Panel
#################################################
# MAIN MENU SCENE
#################################################

func _ready() -> void:
	print("ready")

# Load up an example
func _start_Example(which: String) -> void:
	print("Loading up "+str(which)+" example")
	Loading._load_Scene(which)


func _on_Exit_pressed() -> void:
	get_tree().quit()

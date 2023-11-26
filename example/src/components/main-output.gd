extends VBoxContainer
#################################################
# MAIN OUTPUT COMPONENT
#################################################
func _ready() -> void:
	$Text.clear()


func add_new_text(this_message: String) -> void:
	$Text.append_bbcode(this_message+"\n")

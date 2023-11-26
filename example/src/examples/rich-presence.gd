extends Panel
#################################################
# RICH PRESENCE EXAMPLE
#################################################
var current_key: int = 0
var rich_presence: Dictionary = {
	0:"#StatusWithoutScore",
	1:"#StatusWithScore",
	2:"#Status_AtMainMenu",
	3:"#Status_WaitingForMatch",
	4:"#Status_Winning",
	5:"#Status_Losing",
	6:"#Status_Tied"
}


func _ready() -> void:
	for rich_presence_key in rich_presence.keys():
		$Frame/Main/Pick/Keys.add_item(rich_presence[rich_presence_key])


func _on_get_key_count_pressed() -> void:
	var key_count: int = Steam.getFriendRichPresenceKeyCount(Global.steam_id)
	get_node("%Output").add_new_text("Current player key count: %s" % key_count)


func _on_get_rich_presence_pressed() -> void:
	var this_key: String = Steam.getFriendRichPresence(Global.steam_id, rich_presence[current_key])
	get_node("%Output").add_new_text("Current key used: %s" % this_key)


func _on_keys_item_selected(this_index: int) -> void:
	get_node("%Output").add_new_text("Setting key to current: %s" % this_index)
	current_key = this_index


func _on_set_rich_presence_pressed() -> void:
	var setting_presence: bool = Steam.setRichPresence("steam_display", rich_presence[current_key])
	get_node("%Output").add_new_text("Setting rich presence to %s (%s): %s" % [rich_presence[current_key], current_key, setting_presence])


#################################################
# HELPER FUNCTIONS
#################################################
func _on_back_pressed() -> void:
	Loading.load_scene("main")


func _on_valve_docs_pressed() -> void:
	if OS.shell_open("https://partner.steamgames.com/doc/features/enhancedrichpresence") > 0:
		print("[ERROR] Failed to open Valve's documentation link.")

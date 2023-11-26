extends Panel
#################################################
# OUTPUT COMPONENT
#################################################


func _ready() -> void:
	if Global.is_online:
		$Status/Title.set_text("Steamworks Status (Online)")
	else:
		$Status/Title.set_text("Steamworks Status (Offline)")
	$Status/ID.set_text("Steam ID: %s" % Global.steam_id)
	$Status/Username.set_text("Username: %s" % Global.steam_username)
	$Status/Owns.set_text("Owns App: %s" % Global.is_owned)

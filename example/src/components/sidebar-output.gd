extends Panel
#################################################
# OUTPUT COMPONENT
#################################################
# Displays general Steamworks stuff


func _ready() -> void:
	if Global.is_online:
		$Status/Title.set_text("Steamworks Status (Online)")
	else:
		$Status/Title.set_text("Steamworks Status (Offline)")
	$Status/ID.set_text("Steam ID: "+str(Global.steam_id))
	$Status/Username.set_text("Username: "+str(Global.steam_username))
	$Status/Owns.set_text("Owns App: "+str(Global.is_owned))

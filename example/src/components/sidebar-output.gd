extends Panel
#################################################
# OUTPUT COMPONENT
#################################################
# Display general Steamworks stuff
func _ready() -> void:
	if Global.IS_ONLINE:
		$Status/Title.set_text("Steamworks Status (Online)")
	else:
		$Status/Title.set_text("Steamworks Status (Offline)")
	$Status/ID.set_text("Steam ID: "+str(Global.STEAM_ID))
	$Status/Username.set_text("Username: "+str(Global.STEAM_USERNAME))
	$Status/Owns.set_text("Owns App: "+str(Global.IS_OWNED))

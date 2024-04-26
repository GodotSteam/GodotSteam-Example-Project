extends Node
#################################################
# GODOTSTEAM EXAMPLE PROJECT v4.0
#################################################

var is_on_steam: bool = false
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_id: int = 0
var steam_username: String = "[not set]"


func _ready() -> void:
	print("Starting the GodotSteam example project...")
	_initialize_steam()
	
	Helper.connect_signal(Steam.steamworks_error, _on_steamworks_error, 2)

	if is_on_steam_deck:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN


# Process all Steamworks callbacks
func _process(_delta: float) -> void:
	if is_on_steam:
		Steam.run_callbacks()


#################################################
# INITIALIZING STEAM
# https://godotsteam.com/tutorials/initializing/
#################################################

func _initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		OS.set_environment("SteamAppId", str(480))
		OS.set_environment("SteamGameId", str(480))
		
		var init_response: Dictionary = Steam.steamInit(false)
		# If the status isn't one, print out the possible error and quit the program
		if init_response['status'] != 1:
			printerr("[STEAM] Failed to initialize: %s Shutting down..." % 
				str(init_response['verbal']))
			get_tree().quit()

		# Is the user actually using Steam; if false, 
		# the app assumes this is a non-Steam version
		is_on_steam = true
		
		# Checking if the app is on Steam Deck to modify certain behaviors
		is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
		
		# Acquire information about the user
		is_online = Steam.loggedOn()
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()

		# Check if account owns the game
		is_owned = Steam.isSubscribed()
		
		if is_owned == false:
			printerr("[STEAM] User does not own this game")
			# Uncomment this line to close the game if the user does not own the game
			#get_tree().quit()
		
	else:
		printerr("Engine does not have the Steam Singleton! Please make sure \n
		you add GodotSteam as a GDNative / GDExtension Plug-in, or with a \n
		compiled Godot version including GodotSteam / Steamworks.\n\n
		For more information, visit https://godotsteam.com/")


# Intended to serve as generic error messaging for failed call results.
# Note: this callback is unique to GodotSteam.
func _on_steamworks_error(failed_signal : String, message : String):
	printerr("[GODOTSTEAM] Steamworks Error! Failed Signal %s: %s" %
			[failed_signal, message]) 

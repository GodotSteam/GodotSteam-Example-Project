extends Node
#################################################
# GODOTSTEAM EXAMPLE PROJECT v3.0
#################################################
var IS_ON_STEAM: bool = false
var IS_ON_STEAM_DECK: bool = false
var IS_ONLINE: bool = false
var IS_OWNED: bool = false
var STEAM_ID: int = 0
var STEAM_USERNAME: String = "No one"


func _ready() -> void:
	print("Starting the GodotSteam Example project...")
	_initialize_Steam()

	if IS_ON_STEAM_DECK:
		OS.set_window_fullscreen(true)


func _initialize_Steam() -> void:
	if Engine.has_singleton("Steam"):
		var INIT: Dictionary = Steam.steamInit(false)
		# If the status isn't one, print out the possible error and quit the program
		if INIT['status'] != 1:
			print("[STEAM] Failed to initialize: "+str(INIT['verbal'])+" Shutting down...")
			get_tree().quit()

		# Is the user actually using Steam; if false, the app assumes this is a non-Steam version
		IS_ON_STEAM = true
		# Checking if the app is on Steam Deck to modify certain behaviors
		IS_ON_STEAM_DECK = Steam.isSteamRunningOnSteamDeck()
		# Acquire information about the user
		IS_ONLINE = Steam.loggedOn()
		IS_OWNED = Steam.isSubscribed()
		STEAM_ID = Steam.getSteamID()
		STEAM_USERNAME = Steam.getPersonaName()

		# Check if account owns the game
		if IS_OWNED == false:
			print("[STEAM] User does not own this game")
			# Uncomment this line to close the game if the user does not own the game
			#get_tree().quit()


# Process all Steamworks callbacks
func _process(_delta: float) -> void:
	if IS_ON_STEAM:
		Steam.run_callbacks()

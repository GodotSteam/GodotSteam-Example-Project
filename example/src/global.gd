extends Node
#################################################
# GODOTSTEAM EXAMPLE PROJECT
#################################################
var is_on_steam: bool = false
var is_on_steam_deck: bool = false
var is_online: bool = false
var is_owned: bool = false
var steam_app_id: int = 480
var steam_id: int = 0
var steam_username: String = "No one"


func _init() -> void:
	if not OS.set_environment("SteamAppId", str(steam_app_id)):
		push_error("[ERROR] Could not set SteamAppId variable, Steamworks will not function")
	if not OS.set_environment("GameAppId", str(steam_app_id)):
		push_error("[ERROR] Could not set GameAppId variable, Steamworks will not function")


func _ready() -> void:
	print("Starting the GodotSteam Example project...")
	initialize_steam()
	set_custom_mouse()

	if is_on_steam_deck:
		OS.set_window_fullscreen(true)


func initialize_steam() -> void:
	if Engine.has_singleton("Steam"):
		var initialization_response: Dictionary = Steam.steamInitEx(false)
		# If the status isn't one, print out the possible error and quit the program
		if initialization_response['status'] != 0:
			print("Failed to initialize: "+str(initialization_response['verbal'])+" Shutting down...")
			get_tree().quit()

		# Is the user actually using Steam; if false, the app assumes this is a non-Steam version
		is_on_steam = true
		# Checking if the app is on Steam Deck to modify certain behaviors
		is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
		# Acquire information about the user
		is_online = Steam.loggedOn()
		is_owned = Steam.isSubscribed()
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()

		# Check if account owns the game
		if is_owned == false:
			print("User does not own this game")
			# Uncomment the line below to close the game if the user does not own the game
			#get_tree().quit()
	# If the engine doesn't have the Steam class, then the app assumes this is a non-Steam version
	# This is useful for shipping your game on other stores or platforms
	else:
		print("[NOTICE] This is the non-Steam version of the app!")
		is_on_steam = false


# The `run_callbacks` function must be run in a constantly active `_process` function
# to get Steamworks callbacks
func _process(_delta: float) -> void:
	if is_on_steam:
		Steam.run_callbacks()


func set_custom_mouse() -> void:
	var mouse_texture: Texture = load("res://data/images/mouse-hover.png")
	Input.set_custom_mouse_cursor(mouse_texture, Input.CURSOR_POINTING_HAND, Vector2(0, 0))

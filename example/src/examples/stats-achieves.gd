extends Panel
#################################################
# STATS AND ACHIEVEMENTS EXAMPLE
#################################################
# These variables are specific to SpaceWar (app 480)
var ACHIEVEMENTS: Dictionary = {
	"ACH_TRAVEL_FAR_ACCUM": false,
	"ACH_TRAVEL_FAR_SINGLE": false,
	"ACH_WIN_100_GAMES": false,
	"ACH_WIN_ONE_GAME": false
	}
var STATISTICS: Dictionary = {
	"FeetTraveled": 0.0,
	"MaxFeetTraveled": 0.0,
	"NumGames": 0,
	"NumLosses": 0,
	"NumWins": 0
	}


func _ready() -> void:
	# Connect some signals
	_connect_Steam_Signals("current_stats_received", "_steam_Stats_Ready")
	_connect_Steam_Signals("user_stats_received", "_steam_Stats_Ready")

	# Add options to the drop-downs
	for ACHIEVEMENT in ACHIEVEMENTS.keys():
		$Frame/Main/Selections/Grid/Achievements.add_item(ACHIEVEMENT)
	for STATISTIC in STATISTICS.keys():
		$Frame/Main/Selections/Grid/Statistics/Select.add_item(STATISTIC)


#################################################
# EXTRA FUNCTIONS FOR THE EXAMPLE
#################################################
# Show our achievement list
func _update_Achievement_List() -> void:
	# Loop through keys and set the display
	for A in ACHIEVEMENTS.keys():
		match A:
			"ACH_WIN_ONE_GAME": $Frame/Main/Readout/Achievements/List/Grid/Value1.set_text(str(ACHIEVEMENTS[A]))
			"ACH_WIN_100_GAMES": $Frame/Main/Readout/Achievements/List/Grid/Value2.set_text(str(ACHIEVEMENTS[A]))
			"ACH_TRAVEL_FAR_ACCUM": $Frame/Main/Readout/Achievements/List/Grid/Value3.set_text(str(ACHIEVEMENTS[A]))
			"ACH_TRAVEL_FAR_SINGLE": $Frame/Main/Readout/Achievements/List/Grid/Value4.set_text(str(ACHIEVEMENTS[A]))


# Show our statistics list
func _update_Stat_List() -> void:
	# Loop through keys and set the display
	for S in STATISTICS.keys():
		match S:
			"NumGames": $Frame/Main/Readout/Statistics/List/Grid/Value1.set_text(str(STATISTICS[S]))
			"NumWins": $Frame/Main/Readout/Statistics/List/Grid/Value2.set_text(str(STATISTICS[S]))
			"NumLosses": $Frame/Main/Readout/Statistics/List/Grid/Value3.set_text(str(STATISTICS[S]))
			"FeetTraveled": $Frame/Main/Readout/Statistics/List/Grid/Value4.set_text(str(STATISTICS[S]))
			"MaxFeetTraveled": $Frame/Main/Readout/Statistics/List/Grid/Value5.set_text(str(STATISTICS[S]))


#################################################
# STEAM STATISTIC RETRIEVAL
#################################################
# Request the current, local user's achievements and stats
# This will fire by default once Steamworks is initialized
func _on_requestCurrentStats_pressed() -> void:
	if not Steam.requestCurrentStats():
		print("Failed to request current stats from Steam!")


# Request the given user's achievements and stats
func _on_requestUserStats_pressed() -> void:
	Steam.requestUserStats(Global.STEAM_ID)


# Handle callback from requesting user data
func _steam_Stats_Ready(game: int, result: bool, user: int) -> void:
	# Minor debug information
	$Frame/Main/Output.append_text("[STEAM] This game's ID: "+str(game)+"\n")
	$Frame/Main/Output.append_text("[STEAM] Call result: "+str(result)+"\n")
	$Frame/Main/Output.append_text("[STEAM] This user's Steam ID: "+str(user)+"\n")

	# Get achievements and pass them to variables
	_get_Achievement("ACH_WIN_ONE_GAME")
	_get_Achievement("ACH_WIN_100_GAMES")
	_get_Achievement("ACH_TRAVEL_FAR_ACCUM")
	_get_Achievement("ACH_TRAVEL_FAR_SINGLE")

	# Update our achievement list to see
	_update_Achievement_List()

	# Get statistics (int) and pass them to variables
	STATISTICS["NumGames"] = Steam.getStatInt("NumGames")
	STATISTICS["NumWins"] = Steam.getStatInt("NumWins")
	STATISTICS["NumLosses"] = Steam.getStatInt("NumLosses")
	STATISTICS["FeetTraveled"] = Steam.getStatFloat("FeetTraveled")
	STATISTICS["MaxFeetTraveled"] = Steam.getStatFloat("MaxFeetTraveled")

	# Update our stat list to see
	_update_Stat_List()


##################################################
# STATISTIC FUNCTIONS
##################################################
func _on_setStats_pressed() -> void:
	# Acquire the statistic name from the drop-down
	# Awful way to do this, but only necessary for the example (NEVER DO THIS)
	var THIS_ID: int = $Frame/Main/Selections/Grid/Statistics/Select.get_selected_id()
	var THIS_STAT: String = $Frame/Main/Selections/Grid/Statistics/Select.get_item_text(THIS_ID)

	# Acquire the new value
	var THIS_VALUE: String = $Frame/Main/Selections/Grid/Statistics/Amount.get_text()

	# If this statistic is 1-3 then it is an INT
	var IS_SET: bool = false
	if THIS_ID <= 3:
		IS_SET = Steam.setStatInt(THIS_STAT, int(THIS_VALUE))
	# Else this is a float-based statistic
	else:
		IS_SET = Steam.setStatFloat(THIS_STAT, float(THIS_VALUE))
	$Frame/Main/Output.append_text("[STEAM] Statistic for "+str(THIS_STAT)+" stored: "+str(IS_SET)+"\n")
	
	# The stats must be pushed to Steam to register
	var STORE_STATS: bool = Steam.storeStats()
	$Frame/Main/Output.append_text("[STEAM] Stats and achievements stored correctly: "+str(STORE_STATS)+"\n")


##################################################
# ACHIEVEMENT FUNCTIONS
##################################################
# Process achievements
func _get_Achievement(achievement_name: String) -> void:
	var ACHIEVE: Dictionary = Steam.getAchievement(achievement_name)
	# Achievement exists
	if ACHIEVE['ret']:
		# Achievement is unlocked
		if ACHIEVE['achieved']:
			ACHIEVEMENTS[achievement_name] = true
		# Achievement is locked
		else:
			ACHIEVEMENTS[achievement_name] = false
	# Achievement does not exist
	else:
		ACHIEVEMENTS[achievement_name] = false


func _on_getAchievementIcon_pressed() -> void:
	# Acquire the achievement name from the drop-down
	# Awful way to do this, but only necessary for the example (NEVER DO THIS)
	var THIS_ID: int = $Frame/Main/Selections/Grid/Achievements.get_selected_id()
	var THIS_ACHIEVE: String = $Frame/Main/Selections/Grid/Achievements.get_item_text(THIS_ID)

	# Set up some icon variables
	var SIZE: int = 64
	
	# Get the image's handle
	var HANDLE: int = Steam.getAchievementIcon(THIS_ACHIEVE)

	# Get the image data
	var BUFFER: Dictionary = Steam.getImageRGBA(HANDLE)

	# If this succeeds
	if BUFFER['success']:
		# Create the image and texture for loading
		var ICON: Image = Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGBA8, BUFFER['buffer'])
		# Apply it to the texture
		var ICON_TEXTURE: ImageTexture = ImageTexture.create_from_image(ICON)

		# Display it
		$Frame/Main/Readout/Achievements/List/Icon/Icon.set_texture(ICON_TEXTURE)
	else:
		$Frame/Main/Output.append_text("Failed to retrieve achievement icon\n\n")


# Fire a Steam achievement
# Must contain the same name as what is listed in your Steamworks back-end
func _on_setAchievement_pressed() -> void:
	# Acquire the achievement name from the drop-down
	# Awful way to do this, but only necessary for the example (NEVER DO THIS)
	var THIS_ID: int = $Frame/Main/Selections/Grid/Achievements.get_selected_id()
	var THIS_ACHIEVE: String = $Frame/Main/Selections/Grid/Achievements.get_item_text(THIS_ID)

	# Set the achievement value locally
	ACHIEVEMENTS[THIS_ACHIEVE] = true

	# Pass the value to Steam
	var SET_ACHIEVE: bool = Steam.setAchievement(THIS_ACHIEVE)
	$Frame/Main/Output.append_text("[STEAM] Achievement "+str(THIS_ACHIEVE)+" set correctly: "+str(SET_ACHIEVE)+"\n")

	# Now fire it so it appears to the player
	var STORE_STATS: bool = Steam.storeStats()
	$Frame/Main/Output.append_text("[STEAM] Stats and achievements stored correctly: "+str(STORE_STATS)+"\n")

	# Update our list to see
	_update_Achievement_List()


#################################################
# STATISTICS RESETTING
#################################################
# This will reset all statistics the user has on Steam
# Setting the variable to true will also reset their achievements
func _on_resetAllStats_pressed() -> void:
	var ACHIEVEMENTS_TOO: bool = true
	var IS_RESET: bool = Steam.resetAllStats(ACHIEVEMENTS_TOO)
	$Frame/Main/Output.append_text("[STEAM] Statistics and achievements reset: "+str(IS_RESET)+"\n")
	
	# Make sure to request the updated stats and achievements
	_on_requestUserStats_pressed()


#################################################
# HELPER FUNCTIONS
#################################################
func _on_Back_pressed() -> void:
	Loading._load_Scene("main")


# Connect a Steam signal and show the success code
func _connect_Steam_Signals(this_signal: String, this_function: String) -> void:
	var SIGNAL_CONNECT: int = Steam.connect(this_signal, Callable(self, this_function))
	if SIGNAL_CONNECT > OK:
		print("[STEAM] Connecting "+str(this_signal)+" to "+str(this_function)+" failed: "+str(SIGNAL_CONNECT))

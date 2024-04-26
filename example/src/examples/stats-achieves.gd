extends Panel
#################################################
# STATS AND ACHIEVEMENTS EXAMPLE
#################################################
# These variables are specific to SpaceWar (app 480)

var achievements_dict: Dictionary = {
	"ACH_TRAVEL_FAR_ACCUM": false,
	"ACH_TRAVEL_FAR_SINGLE": false,
	"ACH_WIN_100_GAMES": false,
	"ACH_WIN_ONE_GAME": false
	}
	
var statistics_dict: Dictionary = {
	"FeetTraveled": 0.0,
	"MaxFeetTraveled": 0.0,
	"NumGames": 0,
	"NumLosses": 0,
	"NumWins": 0
	}

@onready var output: RichTextLabel = $Frame/Main/Output

func _ready() -> void:
	# Connect some signals
	
	Helper.connect_signal(Steam.current_stats_received, _on_current_stats_received)
	Helper.connect_signal(Steam.user_stats_received, _on_user_stats_received)

	# Add options to the drop-downs
	for ACHIEVEMENT in achievements_dict.keys():
		$Frame/Main/Selections/Grid/Achievements.add_item(ACHIEVEMENT)
	for STATISTIC in statistics_dict.keys():
		$Frame/Main/Selections/Grid/Statistics/Select.add_item(STATISTIC)


##################################################
# STATISTIC FUNCTIONS
##################################################

func _on_set_stats_pressed() -> void:
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
	output.append_text("[STEAM] Statistic for "+str(THIS_STAT)+" stored: "+str(IS_SET)+"\n")
	
	# The stats must be pushed to Steam to register
	var STORE_STATS: bool = Steam.storeStats()
	output.append_text("[STEAM] Stats and achievements stored correctly: "+str(STORE_STATS)+"\n")


##################################################
# ACHIEVEMENT FUNCTIONS
##################################################

# Process achievements
func update_achievement_state(achievement_name: String) -> void:
	var achievement: Dictionary = Steam.getAchievement(achievement_name)
	# Achievement exists
	if achievement['ret']:
		# Achievement is unlocked
		if achievement['achieved']:
			achievements_dict[achievement_name] = true
		# Achievement is locked
		else:
			achievements_dict[achievement_name] = false
	# Achievement does not exist
	else:
		achievements_dict[achievement_name] = false


func _on_get_achievement_icon_pressed() -> void:
	# Acquire the achievement name from the drop-down
	# Awful way to do this, but only necessary for the example (NEVER DO THIS)
	var this_id: int = $Frame/Main/Selections/Grid/Achievements.get_selected_id()
	var this_achievement: String = $Frame/Main/Selections/Grid/Achievements.get_item_text(this_id)

	# Set up some icon variables
	var size: int = 64
	
	# Get the image's handle
	var handle: int = Steam.getAchievementIcon(this_achievement)

	# Get the image data
	var buffer: Dictionary = Steam.getImageRGBA(handle)

	# If this succeeds
	if buffer['success']:
		# Create the image and texture for loading
		var icon: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer['buffer'])
		# Apply it to the texture
		var icon_texture: ImageTexture = ImageTexture.create_from_image(icon)

		# Display it
		$Frame/Main/Readout/Achievements/List/Icon/Icon.set_texture(icon_texture)
	else:
		output.append_text("Failed to retrieve achievement icon\n\n")


# Fire a Steam achievement
# Must contain the same name as what is listed in your Steamworks back-end
func _on_set_achievement_pressed() -> void:
	# Acquire the achievement name from the drop-down
	# Awful way to do this, but only necessary for the example (NEVER DO THIS)
	var this_id: int = $Frame/Main/Selections/Grid/Achievements.get_selected_id()
	var this_achievement: String = $Frame/Main/Selections/Grid/Achievements.get_item_text(this_id)

	# Set the achievement value locally
	achievements_dict[this_achievement] = true

	# Pass the value to Steam
	var set_achievement: bool = Steam.setAchievement(this_achievement)
	output.append_text("[STEAM] Achievement "+str(this_achievement)+" set correctly: "+str(set_achievement)+"\n")

	# Now fire it so it appears to the player
	var score_stats: bool = Steam.storeStats()
	output.append_text("[STEAM] Stats and achievements stored correctly: "+str(score_stats)+"\n")

	# Update our list to see
	update_achievement_list()


#################################################
# EXTRA FUNCTIONS FOR THE EXAMPLE
#################################################

# Show our achievement list
func update_achievement_list() -> void:
	# Loop through keys and set the display
	for A in achievements_dict.keys():
		match A:
			"ACH_WIN_ONE_GAME": $Frame/Main/Readout/Achievements/List/Grid/Value1.set_text(str(achievements_dict[A]))
			"ACH_WIN_100_GAMES": $Frame/Main/Readout/Achievements/List/Grid/Value2.set_text(str(achievements_dict[A]))
			"ACH_TRAVEL_FAR_ACCUM": $Frame/Main/Readout/Achievements/List/Grid/Value3.set_text(str(achievements_dict[A]))
			"ACH_TRAVEL_FAR_SINGLE": $Frame/Main/Readout/Achievements/List/Grid/Value4.set_text(str(achievements_dict[A]))


# Show our statistics list
func update_stat_list() -> void:
	# Loop through keys and set the display
	for S in statistics_dict.keys():
		match S:
			"NumGames": $Frame/Main/Readout/Statistics/List/Grid/Value1.set_text(str(statistics_dict[S]))
			"NumWins": $Frame/Main/Readout/Statistics/List/Grid/Value2.set_text(str(statistics_dict[S]))
			"NumLosses": $Frame/Main/Readout/Statistics/List/Grid/Value3.set_text(str(statistics_dict[S]))
			"FeetTraveled": $Frame/Main/Readout/Statistics/List/Grid/Value4.set_text(str(statistics_dict[S]))
			"MaxFeetTraveled": $Frame/Main/Readout/Statistics/List/Grid/Value5.set_text(str(statistics_dict[S]))


# This will reset all statistics the user has on Steam
# Setting the variable to true will also reset their achievements
func _on_reset_all_stats_pressed() -> void:
	var clear_achievements: bool = true
	var is_reset: bool = Steam.resetAllStats(clear_achievements)
	output.append_text("[STEAM] Statistics and achievements reset: "+str(is_reset)+"\n")
	
	# Make sure to request the updated stats and achievements
	_on_request_current_stats_pressed()


#################################################
# STEAM STATISTIC RETRIEVAL
#################################################

# Request the current, local user's achievements and stats
# This will fire by default once Steamworks is initialized
func _on_request_current_stats_pressed() -> void:
	if not Steam.requestCurrentStats():
		printerr("Failed to request current stats from Steam!")


# Request the given user's achievements and stats
func _on_request_user_stats_pressed() -> void:
	Steam.requestUserStats(Global.steam_id)


func handle_received_stats(game: int, result: bool, user: int):
	# Minor debug information
	output.append_text("[STEAM] This game's ID: "+str(game)+"\n")
	output.append_text("[STEAM] Call result: "+str(result)+"\n")
	output.append_text("[STEAM] This user's Steam ID: "+str(user)+"\n")

	# Get achievements and pass them to variables
	update_achievement_state("ACH_WIN_ONE_GAME")
	update_achievement_state("ACH_WIN_100_GAMES")
	update_achievement_state("ACH_TRAVEL_FAR_ACCUM")
	update_achievement_state("ACH_TRAVEL_FAR_SINGLE")

	# Update our achievement list to see
	update_achievement_list()

	# Get statistics (int) and pass them to variables
	statistics_dict["NumGames"] = Steam.getStatInt("NumGames")
	statistics_dict["NumWins"] = Steam.getStatInt("NumWins")
	statistics_dict["NumLosses"] = Steam.getStatInt("NumLosses")
	statistics_dict["FeetTraveled"] = Steam.getStatFloat("FeetTraveled")
	statistics_dict["MaxFeetTraveled"] = Steam.getStatFloat("MaxFeetTraveled")

	# Update our stat list to see
	update_stat_list()


#################################################
# CALLBACKS
#################################################

#Called when the latest stats and achievements for the local user have been received 
# from the server; in response to function requestCurrentStats.
func _on_current_stats_received(game: int, result: bool, user: int) -> void:
	output.append_text("[STEAM] Current Stats Received: "+str(game)+"\n")
	handle_received_stats(game, result, user)

# Called when the latest stats and achievements for a specific user (including the local user) 
# have been received from the server.
func _on_user_stats_received(game: int, result: bool, user: int) -> void:
	output.append_text("[STEAM] User Stats Received: "+str(game)+"\n")
	handle_received_stats(game, result, user)


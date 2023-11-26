extends Panel
#################################################
# STATS AND ACHIEVEMENTS EXAMPLE
#################################################
# These variables are specific to SpaceWar (app 480)
var achievements: Dictionary = {
	"ACH_TRAVEL_FAR_ACCUM": false,
	"ACH_TRAVEL_FAR_SINGLE": false,
	"ACH_WIN_100_GAMES": false,
	"ACH_WIN_ONE_GAME": false
	}
var statistics: Dictionary = {
	"FeetTraveled": 0.0,
	"MaxFeetTraveled": 0.0,
	"NumGames": 0,
	"NumLosses": 0,
	"NumWins": 0
	}


func _ready() -> void:
	connect_steam_signals("current_stats_received", "_on_steam_stats_ready")
	connect_steam_signals("user_stats_received", "_on_steam_stats_ready")

	# Add options to the drop-downs
	for this_achievement in achievements.keys():
		get_node("%Achievements").add_item(this_achievement)
	for this_statistic in statistics.keys():
		get_node("%Select").add_item(this_statistic)


#################################################
# EXTRA FUNCTIONS FOR THE EXAMPLE
#################################################
# Show our achievement list
func update_achievement_list() -> void:
	# Loop through keys and set the display
	for this_achievement in achievements.keys():
		match this_achievement:
			"ACH_WIN_ONE_GAME": get_node("%Value1").set_text(str(achievements[this_achievement]))
			"ACH_WIN_100_GAMES": get_node("%Value2").set_text(str(achievements[this_achievement]))
			"ACH_TRAVEL_FAR_ACCUM": get_node("%Value3").set_text(str(achievements[this_achievement]))
			"ACH_TRAVEL_FAR_SINGLE": get_node("%Value4").set_text(str(achievements[this_achievement]))


# Show our statistics list
func update_stat_list() -> void:
	# Loop through keys and set the display
	for this_stat in statistics.keys():
		match this_stat:
			"NumGames": $Frame/Main/Readout/Statistics/List/Grid/Value1.set_text(str(statistics[this_stat]))
			"NumWins": $Frame/Main/Readout/Statistics/List/Grid/Value2.set_text(str(statistics[this_stat]))
			"NumLosses": $Frame/Main/Readout/Statistics/List/Grid/Value3.set_text(str(statistics[this_stat]))
			"FeetTraveled": $Frame/Main/Readout/Statistics/List/Grid/Value4.set_text(str(statistics[this_stat]))
			"MaxFeetTraveled": $Frame/Main/Readout/Statistics/List/Grid/Value5.set_text(str(statistics[this_stat]))


#################################################
# STEAM STATISTIC RETRIEVAL
#################################################
# Request the current, local user's achievements and stats
# This will fire by default once Steamworks is initialized
func _on_request_current_stats_pressed() -> void:
	if not Steam.requestCurrentStats():
		get_node("%Output").add_new_text("Failed to request current stats from Steam")


# Request the given user's achievements and stats
func _on_request_user_stats_pressed() -> void:
	if not Steam.requestUserStats(Global.steam_id):
		get_node("%Output").add_new_text("Failed to request user stats from Steam")


# Handle callback from requesting user data
func _on_steam_stats_ready(game: int, result: bool, user: int) -> void:
	# Minor debug information
	get_node("%Output").add_new_text("This game's ID: %s" % game)
	get_node("%Output").add_new_text("Call result: %s" % result)
	get_node("%Output").add_new_text("This user's Steam ID: %s" % user)

	# Get achievements and pass them to variables
	get_achievement("ACH_WIN_ONE_GAME")
	get_achievement("ACH_WIN_100_GAMES")
	get_achievement("ACH_TRAVEL_FAR_ACCUM")
	get_achievement("ACH_TRAVEL_FAR_SINGLE")

	# Update our achievement list to see
	update_achievement_list()

	# Get statistics (int) and pass them to variables
	statistics["NumGames"] = Steam.getStatInt("NumGames")
	statistics["NumWins"] = Steam.getStatInt("NumWins")
	statistics["NumLosses"] = Steam.getStatInt("NumLosses")
	statistics["FeetTraveled"] = Steam.getStatFloat("FeetTraveled")
	statistics["MaxFeetTraveled"] = Steam.getStatFloat("MaxFeetTraveled")

	# Update our stat list to see
	update_stat_list()


##################################################
# STATISTIC FUNCTIONS
##################################################
func _on_set_stats_pressed() -> void:
	# Acquire the statistic name from the drop-down
	# Awful way to do this, but only necessary for the example (NEVER DO THIS)
	var this_id: int = get_node("%Select").get_selected_id()
	var this_stat: String = get_node("%Select").get_item_text(this_id)
	# Acquire the new value
	var this_value: String = get_node("%Amount").get_text()

	# If this statistic is 1-3 then it is an INT
	var is_set: bool = false
	if this_id <= 3:
		is_set = Steam.setStatInt(this_stat, int(this_value))
	# Else this is a float-based statistic
	else:
		is_set = Steam.setStatFloat(this_stat, float(this_value))
	get_node("%Output").add_new_text("Statistic for %s stored: %s" % [this_stat, is_set])
	
	# The stats must be pushed to Steam to register
	var store_stats: bool = Steam.storeStats()
	get_node("%Output").add_new_text("Stats and achievements stored correctly: %s" % store_stats)


##################################################
# ACHIEVEMENT FUNCTIONS
##################################################
# Process achievements
func get_achievement(achievement_name: String) -> void:
	var this_achievement: Dictionary = Steam.getAchievement(achievement_name)
	# Achievement exists
	if this_achievement['ret']:
		# Achievement is unlocked
		if this_achievement['achieved']:
			achievements[achievement_name] = true
		# Achievement is locked
		else:
			achievements[achievement_name] = false
	# Achievement does not exist
	else:
		achievements[achievement_name] = false


func _on_get_achievement_icon_pressed() -> void:
	# Acquire the achievement name from the drop-down
	var this_id: int = get_node("%Achievements").get_selected_id()
	var this_achieve: String = get_node("%Achievements").get_item_text(this_id)

	var icon_size: int = 64
	var icon_handle: int = Steam.getAchievementIcon(this_achieve)
	var icon_buffer: Dictionary = Steam.getImageRGBA(icon_handle)
	
	if icon_buffer['success']:
		# Create the image and texture for loading
		var icon: Image = Image.new()
		icon.create_from_data(icon_size, icon_size, false, Image.FORMAT_RGBA8, icon_buffer['buffer'])
		# Apply it to the texture
		var icon_texture: ImageTexture = ImageTexture.new()
		icon_texture.create_from_image(icon)
		# Display it
		get_node("%Icon").set_texture(icon_texture)


# Fire a Steam achievement
# Must contain the same name as what is listed in your Steamworks back-end
func _on_set_achievement_pressed() -> void:
	# Acquire the achievement name from the drop-down
	var this_id: int = get_node("%Achievements").get_selected_id()
	var this_achieve: String = get_node("%Achievements").get_item_text(this_id)

	# Set the achievement value locally
	achievements[this_achieve] = true

	# Pass the value to Steam
	var set_achieve: bool = Steam.setAchievement(this_achieve)
	get_node("%Output").add_new_text("Achievement %s set correctly: %s" % [this_achieve, set_achieve])

	# Now fire it so it appears to the player
	var store_stats: bool = Steam.storeStats()
	get_node("%Output").add_new_text("Stats and achievements stored correctly: %s" % store_stats)

	# Update our list to see
	update_achievement_list()


#################################################
# STATISTICS RESETTING
#################################################
# This will reset all statistics the user has on Steam
# Setting the variable to true will also reset their achievements
func _on_reset_all_stats_pressed() -> void:
	var achievements_too: bool = true
	var is_reset: bool = Steam.resetAllStats(achievements_too)
	get_node("%Output").add_new_text("Statistics and achievements reset: %s" % is_reset)
	
	# Make sure to request the updated stats and achievements
	_on_request_user_stats_pressed()


#################################################
# HELPER FUNCTIONS
#################################################
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


func _on_back_pressed() -> void:
	Loading.load_scene("main")

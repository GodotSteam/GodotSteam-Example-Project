extends Control
#################################################
# LEADERBOARD EXAMPLE
#################################################
var entry_count: int = 0
var leaderboard_handle: int = 0


func _ready() -> void:
	connect_steam_signals("leaderboard_find_result", "_on_leaderboard_find_result")
	connect_steam_signals("leaderboard_ugc_set", "_on_leaderboard_ugc_set")
	connect_steam_signals("leaderboard_scores_downloaded", "_on_leaderboard_scores_downloaded")


#################################################
# LEADERBOARD FUNCTIONS
#################################################
# Used to attach UGC to a leaderboard score
func _on_attach_leaderboard_ugc_pressed() -> void:
	var ugc_handle: int = 0
	Steam.attachLeaderboardUGC(ugc_handle, leaderboard_handle)
	get_node("%Output").add_new_text("Attaching UGC %s to leaderboard" % ugc_handle)


# Request all rows for a maximum of 100 users
func _on_download_leaderboard_entries_for_users_pressed() -> void:
	# Set an array of users, in this case just the current user
	var user_array: Array = [Global.steam_id]

	# Request them and write to output
	get_node("%Output").add_new_text("Downloading leaderboard entries for handle %s and for users: %s" % [leaderboard_handle, user_array])
	Steam.downloadLeaderboardEntriesForUsers(user_array, leaderboard_handle)


# Request all rows for friends of the current user
func _on_download_leaderboard_entries_pressed() -> void:
	get_node("%Output").add_new_text("Downloading entries for leaderboard %s" % leaderboard_handle)
	Steam.downloadLeaderboardEntries(1, 10, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL, leaderboard_handle)


# Find a leaderboard with a given name
func _on_find_leaderboard_pressed() -> void:
	# Pull leaderboard name from the name field
	var this_leaderboard_name: String = $Frame/Main/Name.get_text()
	get_node("%Output").add_new_text("Finding leaderboard handle for name: %s" % this_leaderboard_name)
	# Find the leaderboard
	Steam.findLeaderboard(this_leaderboard_name)


# Find the given leaderboard or, if it doesn not exist, create it
func _on_find_or_create_leaderboard_pressed() -> void:
	# Set the name, sort method (1 or 2), and display type (1 - 3)
	var this_leaderboard_name: String = $Frame/Main/Name.get_text()
	var leaderboard_sort_method = Steam.LEADERBOARD_SORT_METHOD_ASCENDING
	var leaderboard_display_type = Steam.LEADERBOARD_DISPLAY_TYPE_NUMERIC
	Steam.findOrCreateLeaderboard(this_leaderboard_name, leaderboard_sort_method, leaderboard_display_type)


# Get the name of the leaderboard associated with the current handle
func _on_get_leaderboard_name_pressed() -> void:
	var this_leaderboard_name = Steam.getLeaderboardName(leaderboard_handle)
	# If no name was returned, might be missing or faulty leaderboard handle
	if this_leaderboard_name.empty():
		get_node("%Output").add_new_text("No leaderboard name found, handle is missing or faulty")
	else:
		get_node("%Output").add_new_text("Leaderboard name for handle %s: %s" % [leaderboard_handle, this_leaderboard_name])


# Get the display type of the current handle
func _on_get_leaderboard_display_type_pressed() -> void:
	var display_type: Dictionary = Steam.getLeaderboardDisplayType(leaderboard_handle)
	get_node("%Output").add_new_text("Leaderboard %s display type: %s [%s]" % [leaderboard_handle, display_type['verbal'], display_type['result']])


# Get the number of leaderboard entries
func _on_get_leaderboard_entry_count_pressed() -> void:
	entry_count = Steam.getLeaderboardEntryCount(leaderboard_handle)
	get_node("%Output").add_new_text("Entry count for leaderboard handle %s: %s" % [leaderboard_handle, entry_count])


# Get the sort method of the current handle
func _on_get_leaderboard_sort_method_pressed() -> void:
	var sort_method: Dictionary = Steam.getLeaderboardSortMethod(leaderboard_handle)
	get_node("%Output").add_new_text("Leaderboard %s sort method: %s [%s]" % [leaderboard_handle, sort_method['verbal'], sort_method['result']])


# A leaderboard result was found
func _on_leaderboard_find_result(handle: int, found: int) -> void:
	# The handle was found
	if found == 1:
		# Handle is actually stored internally until it is changed or update, no need to store it locally
		leaderboard_handle = handle
		get_node("%Output").add_new_text("Leaderboard handle: %s (stored internally)" % leaderboard_handle)
	else:
		get_node("%Output").add_new_text("No handle was found for the given leaderboard")


# Leaderboard entries are ready to be retrieved
func _on_leaderboard_scores_downloaded(message: String, this_handle: int, result: Array) -> void:
	var result_print: PoolStringArray = []
	for this_result in result:
		result_print.append("%s\n" % this_result)
	get_node("%Output").add_new_text("Leaderboard entries for handle %s: %s\nResults are as such: %s" % [this_handle, message, result_print])


# UGC has been attached to the leaderboard score
func _on_leaderboard_ugc_set(handle: int, result: String) -> void:
	get_node("%Output").add_new_text("UGC set to handle: %s [%s]" % [handle, result])


#################################################
# HELPER FUNCTIONS
#################################################
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


func _on_back_pressed() -> void:
	Loading.load_scene("main")

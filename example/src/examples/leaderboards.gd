extends Control
#################################################
# LEADERBOARD EXAMPLE
# https://godotsteam.com/tutorials/leaderboards/
#################################################

var entry_count: int = 0
var leaderboard_handle: int = 0


@onready var output: RichTextLabel = $Frame/Main/Output
@onready var leaderboard_name_input: LineEdit = $"Frame/Main/Leaderboard Name"

func _ready() -> void:
	Helper.connect_signal(Steam.leaderboard_ugc_set, _on_leaderboard_UGC_set)
	Helper.connect_signal(Steam.leaderboard_find_result, _on_leaderboard_find_result)
	Helper.connect_signal(Steam.leaderboard_scores_downloaded, _on_leaderboard_scores_downloaded)


#################################################
# LEADERBOARD FUNCTIONS
#################################################

# Used to attach UGC (User Generated Content, the leaderboard entry in this case) to a leaderboard
func _on_attach_leaderboard_UGC_pressed() -> void:
	var UGC_HANDLE: int = 0
	Steam.attachLeaderboardUGC(UGC_HANDLE, leaderboard_handle)
	output.append_text("Attaching UGC "+str(UGC_HANDLE)+" to leaderboard.\n\n")


# Find a leaderboard with a given name
func _on_find_leaderboard_pressed() -> void:
	# Pull leaderboard name from the name field
	var leaderboard_name: String = leaderboard_name_input.get_text()
	output.append_text("Finding leaderboard handle for name: "+str(leaderboard_name)+"\n\n")
	# Find the leaderboard
	Steam.findLeaderboard(leaderboard_name)


# Find the given leaderboard or, if it doesn not exist, create it
func _on_find_or_create_leaderboard_pressed() -> void:
	# Set the name, sort method (1 or 2), and display type (1 - 3)
	var leaderboard_name: String = leaderboard_name_input.get_text()
	var sort_method: int = Steam.LEADERBOARD_SORT_METHOD_ASCENDING
	var display_type: int = Steam.LEADERBOARD_DISPLAY_TYPE_NUMERIC
	
	Steam.findOrCreateLeaderboard(leaderboard_name, sort_method, display_type)


# Get the name of the leaderboard associated with the current handle
func _on_get_leaderboard_name_pressed() -> void:
	var leaderboard_name = Steam.getLeaderboardName(leaderboard_handle)
	# If no name was returned, might be missing or faulty leaderboard handle
	if leaderboard_name.is_empty():
		output.append_text("No leaderboard name found, handle missing or faulty\n\n")
	else:
		output.append_text("Leaderboard name for handle %s: %s\n\n" %
				[str(leaderboard_handle),
				str(leaderboard_name)])


# Get the sort method of the current handle
func _on_get_leaderboard_sort_method_pressed() -> void:
	var sort_method: Dictionary = Steam.getLeaderboardSortMethod(leaderboard_handle)
	output.append_text("Leaderboard %s sort method: %s [%s]\n\n" %
			[str(leaderboard_handle),
			str(sort_method['verbal']),
			str(sort_method['result'])])


# Get the display type of the current handle
func _on_get_leaderboard_display_type_pressed() -> void:
	var DISPLAY_TYPE: Dictionary = Steam.getLeaderboardDisplayType(leaderboard_handle)
	output.append_text("Leaderboard %s display type: %s [%s]\n\n" %
			[str(leaderboard_handle),
			str(DISPLAY_TYPE['verbal']),
			str(DISPLAY_TYPE['result'])])


# Request all rows for friends of the current user
func _on_download_leaderboard_entries_pressed() -> void:
	output.append_text("Downloading entries for leaderboard "+str(leaderboard_handle)+"...\n\n")
	Steam.downloadLeaderboardEntries(1, 10, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL, leaderboard_handle)


# Request all rows for a maximum of 100 users
func _on_download_leaderboard_entries_for_users_pressed() -> void:
	# Set an array of users, in this case just the current user
	var USER_ARRAY: Array = [Global.steam_id]

	# Request them and write to output
	output.append_text("Downloading leaderboard entries for handle %s and for users: %s...\n\n" %
	[str(leaderboard_handle),
	str(USER_ARRAY)])
	
	Steam.downloadLeaderboardEntriesForUsers(USER_ARRAY, leaderboard_handle)


# Get the number of leaderboard entries
func _on_get_leaderboard_entry_count_pressed() -> void:
	entry_count = Steam.getLeaderboardEntryCount(leaderboard_handle)
	output.append_text("Entry count for leaderboard handle %s: %s\n\n" %
			[str(leaderboard_handle),
			str(entry_count)])


#################################################
# CALLBACKS
#################################################

# UGC has been attached to the leaderboard score
func _on_leaderboard_UGC_set(handle: int, result: String) -> void:
	output.append_text("UGC set to handle: "+str(handle)+" ["+str(result)+"]\n\n")


# A leaderboard result was found
func _on_leaderboard_find_result(handle: int, found: int) -> void:
	# The handle was found
	if found == 1:
		# Handle is actually stored internally until it is changed or update, no need to store it locally
		leaderboard_handle = handle
		output.append_text("Leaderboard handle: "+str(leaderboard_handle)+" (stored internally)\n\n")
	else:
		output.append_text("No handle was found for the given leaderboard\n\n")


# Leaderboard entries are ready to be retrieved
func _on_leaderboard_scores_downloaded(message: String, this_handle: int, result: Array) -> void:
	output.append_text("Leaderboard entries for handle "+str(this_handle)+": "+str(message)+"\nResults are as such:\n\n")
	for THIS_RESULT in result:
		output.append_text(str(THIS_RESULT)+"\n\n")

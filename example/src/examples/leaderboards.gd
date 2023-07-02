extends Control
#################################################
# LEADERBOARD EXAMPLE
#################################################
var ENTRY_COUNT: int = 0
var LEADERBOARD_HANDLE: int = 0


func _ready() -> void:
	_connect_Steam_Signals("leaderboard_ugc_set", "_leaderboard_UGC_Set")
	_connect_Steam_Signals("leaderboard_find_result", "_leaderboard_Find_Result")
	_connect_Steam_Signals("leaderboard_scores_downloaded", "_leaderboard_Scores_Downloaded")


#################################################
# LEADERBOARD FUNCTIONS
#################################################
# Used to attach UGC to a leaderboard score
func _on_AttachLeaderboardUGC_pressed() -> void:
	var UGC_HANDLE: int = 0
	Steam.attachLeaderboardUGC(UGC_HANDLE, LEADERBOARD_HANDLE)
	$Frame/Main/Output.append_text("Attaching UGC "+str(UGC_HANDLE)+" to leaderboard.\n\n")


# Find a leaderboard with a given name
func _on_FindLeaderboard_pressed() -> void:
	# Pull leaderboard name from the name field
	var LEADERBOARD: String = $Frame/Main/Name.get_text()
	$Frame/Main/Output.append_text("Finding leaderboard handle for name: "+str(LEADERBOARD)+"\n\n")
	# Find the leaderboard
	Steam.findLeaderboard(LEADERBOARD)


# Find the given leaderboard or, if it doesn not exist, create it
func _on_FindOrCreateLeaderboard_pressed() -> void:
	# Set the name, sort method (1 or 2), and display type (1 - 3)
	var LEADERBOARD: String = $Frame/Main/Name.get_text()
	var LEADERBOARD_SORT_METHOD = Steam.LEADERBOARD_SORT_METHOD_ASCENDING
	var LEADERBOARD_DISPLAY_TYPE = Steam.LEADERBOARD_DISPLAY_TYPE_NUMERIC
	Steam.findOrCreateLeaderboard(LEADERBOARD, LEADERBOARD_SORT_METHOD, LEADERBOARD_DISPLAY_TYPE)


# A leaderboard result was found
func _leaderboard_Find_Result(handle: int, found: int) -> void:
	# The handle was found
	if found == 1:
		# Handle is actually stored internally until it is changed or update, no need to store it locally
		LEADERBOARD_HANDLE = handle
		$Frame/Main/Output.append_text("Leaderboard handle: "+str(LEADERBOARD_HANDLE)+" (stored internally)\n\n")
	else:
		$Frame/Main/Output.append_text("No handle was found for the given leaderboard\n\n")


# Get the name of the leaderboard associated with the current handle
func _on_GetLeaderboardName_pressed() -> void:
	var LEADERBOARD_NAME = Steam.getLeaderboardName(LEADERBOARD_HANDLE)
	# If no name was returned, might be missing or faulty leaderboard handle
	if LEADERBOARD_NAME.is_empty():
		$Frame/Main/Output.append_text("No leaderboard name found, handle is missing or faulty\n\n")
	else:
		$Frame/Main/Output.append_text("Leaderboard name for handle "+str(LEADERBOARD_HANDLE)+": "+str(LEADERBOARD_NAME)+"\n\n")


# Get the sort method of the current handle
func _on_GetLeaderboardSortMethod_pressed() -> void:
	var SORT_METHOD: Dictionary = Steam.getLeaderboardSortMethod(LEADERBOARD_HANDLE)
	$Frame/Main/Output.append_text("Leaderboard "+str(LEADERBOARD_HANDLE)+" sort method: "+str(SORT_METHOD['verbal'])+" ["+str(SORT_METHOD['result'])+"]\n\n")


# Get the display type of the current handle
func _on_GetLeaderboardDisplayType_pressed() -> void:
	var DISPLAY_TYPE: Dictionary = Steam.getLeaderboardDisplayType(LEADERBOARD_HANDLE)
	$Frame/Main/Output.append_text("Leaderboard "+str(LEADERBOARD_HANDLE)+" display type: "+str(DISPLAY_TYPE['verbal'])+" ["+str(DISPLAY_TYPE['result'])+"]\n\n")


# UGC has been attached to the leaderboard score
func _leaderboard_UGC_Set(handle: int, result: String) -> void:
	$Frame/Main/Output.append_text("UGC set to handle: "+str(handle)+" ["+str(result)+"]\n\n")


# Request all rows for friends of the current user
func _on_DownloadLeaderboardEntries_pressed() -> void:
	$Frame/Main/Output.append_text("Downloading entries for leaderboard "+str(LEADERBOARD_HANDLE)+"...\n\n")
	Steam.downloadLeaderboardEntries(1, 10, Steam.LEADERBOARD_DATA_REQUEST_GLOBAL, LEADERBOARD_HANDLE)


# Leaderboard entries are ready to be retrieved
func _leaderboard_Scores_Downloaded(message: String, this_handle: int, result: Array) -> void:
	$Frame/Main/Output.append_text("Leaderboard entries for handle "+str(this_handle)+": "+str(message)+"\nResults are as such:\n\n")
	for THIS_RESULT in result:
		$Frame/Main/Output.append_text(str(THIS_RESULT)+"\n\n")


# Request all rows for a maximum of 100 users
func _on_DownloadLeaderboardEntriesForUsers_pressed() -> void:
	# Set an array of users, in this case just the current user
	var USER_ARRAY: Array = [Global.STEAM_ID]

	# Request them and write to output
	$Frame/Main/Output.append_text("Downloading leaderboard entries for handle "+str(LEADERBOARD_HANDLE)+" and for users: "+str(USER_ARRAY)+"...\n\n")
	Steam.downloadLeaderboardEntriesForUsers(USER_ARRAY, LEADERBOARD_HANDLE)


# Get the number of leaderboard entries
func _on_GetLeaderboardEntryCount_pressed() -> void:
	ENTRY_COUNT = Steam.getLeaderboardEntryCount(LEADERBOARD_HANDLE)
	$Frame/Main/Output.append_text("Entry count for leaderboard handle "+str(LEADERBOARD_HANDLE)+": "+str(ENTRY_COUNT)+"\n\n")


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

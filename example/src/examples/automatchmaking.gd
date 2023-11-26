extends Panel
#################################################
# AUTO-MATCHMAKING EXAMPLE
#################################################
onready var lobby_member = preload("res://src/components/lobby-member.tscn")
var lobby_data: String = ""
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 2
var lobby_vote_kick: bool = false
var matchmaking_phase: int = 0


func _ready() -> void:
	connect_steam_signals("lobby_chat_update", "_on_lobby_chat_update")
	connect_steam_signals("lobby_created", "_on_lobby_created")
	connect_steam_signals("lobby_data_update", "_on_lobby_data_update")
	connect_steam_signals("lobby_joined", "_on_lobby_joined")
	connect_steam_signals("lobby_match_list", "_on_lobby_match_list")
	connect_steam_signals("lobby_message", "_on_lobby_message")
	connect_steam_signals("persona_state_change", "_on_persona_change")


#################################################
# AUTO-MATCHMAKING FUNCTIONS
#################################################
# Iteration for trying different distances
func matchmaking_loop() -> void:
	# If this matchmake_phase is 3 or less, keep going
	if matchmaking_phase < 4:
		###
		# Add other filters for things like game modes, etc.
		# Since this is an example, we cannot set game mode or text match features.
		# However you could use addRequestLobbyListStringFilter to look for specific
		# text in lobby metadata to match different criteria.
		###
		# Set the distance filter
		Steam.addRequestLobbyListDistanceFilter(matchmaking_phase)
		# Request a list
		Steam.requestLobbyList()
	else:
		get_node("%Output").add_new_text("Failed to automatically match you with a lobby. Please try again.\n")


# Start the auto matchmaking process.
func _on_find_lobby_pressed() -> void:
	get_node("%Output").add_new_text("Attempting to find a lobby...\n")
	# Leave a lobby if in one
	if lobby_id > 0:
		_on_leave_lobby_pressed()
	# Set the matchmaking process over
	matchmaking_phase = 0
	# Start the loop!
	matchmaking_loop()


# A lobby list was created, find a possible lobby
func _on_lobby_match_list(these_lobbies: Array) -> void:
	# Set attempting_join to false
	var attempting_join: bool = false
	# Show the list 
	for this_lobby in these_lobbies:
		# Pull lobby data from Steam
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_nums: int = Steam.getNumLobbyMembers(this_lobby)
		###
		# Add other filters for things like game modes, etc.
		# Since this is an example, we cannot set game mode or text match features.
		# However, much like lobby_name, you can use Steam.getLobbyData to get other
		# preset lobby defining data to append to the next if statement.
		###
		# Attempt to join the first lobby that fits the criteria
		if lobby_nums < lobby_members_max and not attempting_join:
			# Turn on attempting_join
			attempting_join = true
			get_node("%Output").add_new_text("Attempting to join lobby %s (%s)..." % [lobby_name, this_lobby])
			Steam.joinLobby(this_lobby)
	# No lobbies that matched were found, go onto the next phase
	if not attempting_join:
		# Increment the matchmake_phase
		matchmaking_phase += 1
		matchmaking_loop()


#################################################
# LOBBY FUNCTIONS
#################################################
# When the player is joining a lobby
func join_lobby(this_lobby_id: int) -> void:
	get_node("%Output").add_new_text("Attempting to join lobby %s" % this_lobby_id)
	# Clear any previous lobby lists
	lobby_members.clear()
	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)


# When the player leaves a lobby for whatever reason
func _on_leave_lobby_pressed() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Append a new message
		get_node("%Output").add_new_text("Leaving lobby %s" % lobby_id)
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)
		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0
		$Frame/Main/Displays/Outputs/Titles/Lobby.set_text("Lobby ID: %s" % lobby_id)
		$Frame/Main/Displays/PlayerList/Title.set_text("Player List (0)")
		# Close session with all users
		for this_member in lobby_members:
			var is_session_closed: bool = Steam.closeP2PSessionWithUser(this_member['steam_id'])
			get_node("%Output").add_new_text("P2P session closed with %s: %s\n" % [this_member['steam_id'], is_session_closed])
		# Clear the local lobby list
		lobby_members.clear()
		for this_member in $Frame/Main/Displays/PlayerList/Players.get_children():
			this_member.hide()
			this_member.queue_free()
		# Disable the leave lobby button and all test buttons
		change_button_controls(true)


# Whan lobby metadata has changed
func _on_lobby_data_update(this_lobby_id: int, member_id: int, key: int) -> void:
	get_node("%Output").add_new_text("Success: lobby ID (%s), member ID (%s), key (%s)" % [this_lobby_id, member_id, key])


# When accepting an invite
func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	# Get the lobby owner's name
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	get_node("%Output").add_new_text("Joining %s's lobby..." % owner_name)
	# Attempt to join the lobby
	join_lobby(this_lobby_id)


# When a lobby is joined
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining succeed, this will be 1
	if response == 1:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		# Print the lobby ID to a label
		$Frame/Main/Displays/Outputs/Titles/Lobby.set_text("Lobby ID: %s" % this_lobby_id)
		# Append to output
		get_node("%Output").add_new_text("Joined lobby %s\n" % this_lobby_id)
		# Get the lobby members
		get_lobby_members()
		# Enable all necessary buttons
		change_button_controls(false)
	# Else it failed for some reason
	else:
		# Get the failure reason
		var fail_reason: String
		match response:
			2:	fail_reason = "This lobby no longer exists."
			3:	fail_reason = "You don't have permission to join this lobby."
			4:	fail_reason = "The lobby is now full."
			5:	fail_reason = "Uh... something unexpected happened!"
			6:	fail_reason = "You are banned from this lobby."
			7:	fail_reason = "You cannot join due to having a limited account."
			8:	fail_reason = "This lobby is locked or disabled."
			9:	fail_reason = "This lobby is community locked."
			10:	fail_reason = "A user in the lobby has blocked you from joining."
			11:	fail_reason = "A user you have blocked is in the lobby."
		get_node("%Output").add_new_text("Failed joining lobby %s: %s\n" % [this_lobby_id, fail_reason])


#################################################
# HELPER FUNCTIONS
#################################################
# Add a new Steam user to the connect users list
func add_player_list(steam_id: int, steam_name: String) -> void:
	print("Adding new player to the list: %s / %s" % [steam_id, steam_name])
	# Add them to the list
	lobby_members.append({"steam_id":steam_id, "steam_name":steam_name})
	# Instance the lobby member object
	var this_member: Object = lobby_member.instance()
	# Add their Steam name and ID
	this_member.name = str(steam_id)
	this_member.set_new_member(steam_id, steam_name)
	# Connect the kick signal
	var this_signal: int = this_member.connect("kick_player", self, "_on_lobby_kick")
	print("Connecting kick_player signal to _on_Lobby_Kick for %s [%s]: %s" % [steam_name, steam_id, this_signal])
	# Add the child node
	$Frame/Main/Displays/PlayerList/Players.add_child(this_member)
	# If you are the host, enable the kick button
	if Global.steam_id == Steam.getLobbyOwner(lobby_id):
		get_node("Frame/Main/Displays/PlayerList/Players/%s/Member/Stuff/Controls/Kick" % this_member.name).set_disabled(false)


# Get the lobby members from Steam
func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()
	# Clear the original player list
	for this_member in $Frame/Main/Displays/PlayerList/Players.get_children():
		this_member.hide()
		this_member.queue_free()
	# Get the number of members from this lobby from Steam
	var num_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	# Update the player list title
	$Frame/Main/Displays/PlayerList/Title.set_text("Player List (%s)" % num_lobby_members)
	# Get the data of these players from Steam
	for this_member in range(0, num_lobby_members):
		print(this_member)
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		# Add them to the player list
		add_player_list(member_steam_id, member_steam_name)


# A user's information has changed
func _on_persona_change(steam_id: int, _flag: int) -> void:
	print("A user (%s) had information change, update the lobby list" % steam_id)
	# Update the player list
	get_lobby_members()


#################################################
# BUTTON FUNCTIONS
#################################################
# Getting associated metadata for the lobby
func _on_get_lobby_data_pressed() -> void:
	lobby_data = Steam.getLobbyData(lobby_id, "name")
	get_node("%Output").add_new_text("Lobby data, name: %s\n" % lobby_data)
	lobby_data = Steam.getLobbyData(lobby_id, "mode")
	get_node("%Output").add_new_text("Lobby data, mode: %s\n" % lobby_data)


#################################################
# LOBBY CHAT FUNCTIONS
#################################################
# Send the message by pressing enter
func _input(this_event: InputEvent) -> void:
	if this_event.is_pressed() and not this_event.is_echo() and this_event.is_action("chat_send"):
		_on_send_chat_pressed()


# When a lobby chat is updated
func _on_lobby_chat_update(this_lobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	# Note that chat state changes is: 1 - entered, 2 - left, 4 - user disconnected before leaving, 8 - user was kicked, 16 - user was banned
	print("Lobby ID: %s, changed ID: %s, making change: %s, chat state: %s" % [this_lobby_id ,changed_id, making_change_id, chat_state])
	# Get the user who has made the lobby change
	var change_maker = Steam.getFriendPersonaName(changed_id)
	# If a player has joined the lobby
	if chat_state == 1:
		get_node("%Output").add_new_text("%s has joined the lobby" % change_maker)
	# Else if a player has left the lobby
	elif chat_state == 2:
		get_node("%Output").add_new_text("%s has left the lobby" % change_maker)
	# Else if a player has been kicked
	elif chat_state == 8:
		get_node("%Output").add_new_text("%s has been kicked from the lobby" % change_maker)
	# Else if a player has been banned
	elif chat_state == 16:
		get_node("%Output").add_new_text("%s has been banned from the lobby" % change_maker)
	# Else there was some unknown change
	else:
		get_node("%Output").add_new_text("%s did... something" % change_maker)
	# Update the lobby now that a change has occurred
	get_lobby_members()


func _on_lobby_kick(kick_id: int) -> void:
	# Pass the kick message to Steam
	var is_sent: bool = Steam.sendLobbyChatMsg(lobby_id, "/kick:"+str(kick_id))
	# Was it send successfully?
	if not is_sent:
		print("[ERROR] Kick command failed to send")


# When a lobby message is received
# Using / delimiter for host commands like kick
func _on_lobby_message(_result: int, user: int, message: String, type: int) -> void:
	# We are only concerned with who is sending the message and what the message is
	var message_sender = Steam.getFriendPersonaName(user)
	# If this is a message or host command
	if type == 1:
		# If the lobby owner and the sender are the same, check for commands
		if user == Steam.getLobbyOwner(lobby_id) and message.begins_with("/"):
			print("Message sender is the lobby owner")
			# Get any commands
			if message.begins_with("/kick"):
				# Get the user ID for kicking
				var these_commands: PoolStringArray = message.split(":", true)
				# If this is your ID, leave the lobby
				if Global.steam_id == int(these_commands[1]):
					_on_leave_lobby_pressed()
		# Else this is just chat message
		else:
			# Print the outpubt before showing the message
			print("%s says: %s" % [message_sender, message])
			get_node("%Output").add_new_text("%s says '%s'\n" % [message_sender, message])
	# Else this is a different type of message
	else:
		match type:
			2: get_node("%Output").add_new_text("%s is typing...\n" % message_sender)
			3: get_node("%Output").add_new_text("%s sent an invite that won't work in this chat!\n" % message_sender)
			4: get_node("%Output").add_new_text("%s sent a text emote that is depreciated.\n" % message_sender)
			6: get_node("%Output").add_new_text("%s has left the chat.\n" % message_sender)
			7: get_node("%Output").add_new_text("%s has entered the chat.\n" % message_sender)
			8: get_node("%Output").add_new_text("%s was kicked!\n" % message_sender)
			9: get_node("%Output").add_new_text("%s was banned!\n" % message_sender)
			10: get_node("%Output").add_new_text("%s disconnected.\n" % message_sender)
			11: get_node("%Output").add_new_text("%s sent an old, offline message.\n" % message_sender)
			12: get_node("%Output").add_new_text("%s sent a link that was removed by the chat filter.\n" % message_sender)


func _on_send_chat_pressed() -> void:
	var message: String = $Frame/Main/Messaging/Chat.get_text()
	# If there is even a message
	if message.length() > 0:
		# Pass the message to Steam
		var is_sent: bool = Steam.sendLobbyChatMsg(lobby_id, message)
		# Was it sent successfully?
		if not is_sent:
			get_node("%Output").add_new_text("[ERROR] Chat message '%s' failed to send.\n" % message)
		# Clear the chat input
		$Frame/Main/Messsaging/Chat.clear()


#################################################
# HELPER FUNCTIONS
#################################################
# Enable or disable a gang of buttons
func change_button_controls(toggle: bool) -> void:
	$Frame/Sidebar/Options/List/Leave.set_disabled(toggle)
	$Frame/Main/Messaging/Send.set_disabled(toggle)
	# Caveat for the lineedit
	if toggle:
		$Frame/Main/Messaging/Chat.set_editable(false)
	else:
		$Frame/Main/Messaging/Chat.set_editable(true)


func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: " % [this_signal, this_function, signal_connect])


func _on_back_pressed() -> void:
	# Leave the lobby if in one
	if lobby_id > 0:
		_on_leave_lobby_pressed()
	Loading.load_scene("main")

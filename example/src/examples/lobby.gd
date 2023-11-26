extends Panel
#################################################
# LOBBY EXAMPLE
#################################################
onready var button_theme = preload("res://data/themes/button-theme.tres")
onready var lobby_member = preload("res://src/components/lobby-member.tscn")

enum lobby_availability {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}

var lobby_data
var lobby_id: int = 0
var lobby_max_members: int = 10
var lobby_members: Array = []
var lobby_vote_kick: bool = false


func _ready() -> void:
	connect_steam_signals("join_requested", "_on_lobby_join_requested")
	connect_steam_signals("lobby_chat_update", "_on_lobby_chat_update")
	connect_steam_signals("lobby_created", "_on_lobby_created")
	connect_steam_signals("lobby_data_update", "_on_lobby_data_update")
	connect_steam_signals("lobby_invite", "_on_lobby_invite")
	connect_steam_signals("lobby_joined", "_on_lobby_joined")
	connect_steam_signals("lobby_match_list", "_on_lobby_match_list")
	connect_steam_signals("lobby_message", "_on_lobby_message")
	connect_steam_signals("p2p_session_request", "_on_p2p_session_request")
	connect_steam_signals("p2p_session_connect_fail", "_on_p2p_session_connect_fail")
	connect_steam_signals("persona_state_change", "_on_persona_change")

	check_command_line()


func _process(_delta: float) -> void:
	# Get packets only if lobby is joined
	if lobby_id > 0:
		read_p2p_packet()


#################################################
# LOBBY FUNCTIONS
#################################################
# When the user starts a game with multiplayer enabled
func _create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobby_id == 0:
		# Set the lobby to public with ten members max
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_max_members)


# When the player is joining a lobby
func join_lobby(this_lobby_id: int) -> void:
	get_node("%Output").add_new_text("Attempting to join lobby %s" % this_lobby_id)
	# Close lobby panel if open
	_on_close_lobbies_pressed()
	# Clear any previous lobby lists
	lobby_members.clear()
	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)


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
		for these_members in lobby_members:
			var session_closed: bool = Steam.closeP2PSessionWithUser(these_members['steam_id'])
			print("P2P session closed with %s: %s" % [these_members['steam_id'], session_closed])
		# Clear the local lobby list
		lobby_members.clear()
		for this_member in $Frame/Main/Displays/PlayerList/Players.get_children():
			this_member.hide()
			this_member.queue_free()
		# Enable the create lobby button
		$Frame/Sidebar/Options/List/CreateLobby.set_disabled(false)
		# Disable the leave lobby button and all test buttons
		change_button_controls(true)


# A lobby has been successfully created
func _on_lobby_created(connect_status: int, this_lobby_id: int) -> void:
	if connect_status == 1:
		get_node("%Output").add_new_text("Created a lobby: %s" % this_lobby_id)

		# Set lobby joinable as a test
		var set_joinable: bool = Steam.setLobbyJoinable(this_lobby_id, true)
		print("The lobby has been set joinable: %s" % set_joinable)

		# Print the lobby ID to a label
		$Frame/Main/Displays/Outputs/Titles/Lobby.set_text("Lobby ID: %s" % this_lobby_id)

		# Set some lobby data
		var set_lobby_data: bool = false
		set_lobby_data = Steam.setLobbyData(this_lobby_id, "name", "%s's Lobby" % Global.steam_username)
		print("Setting lobby name data successful: %s" % set_lobby_data)
		set_lobby_data = Steam.setLobbyData(this_lobby_id, "mode", "GodotSteam test")
		print("Setting lobby mode data successful: %s" % set_lobby_data)

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var is_relay: bool = Steam.allowP2PPacketRelay(true)
		get_node("%Output").add_new_text("Allowing Steam to be relay backup: %s" % is_relay)

		# Enable the leave lobby button and all testing buttons
		change_button_controls(false)
	else:
		get_node("%Output").add_new_text("Failed to create lobby")


# Whan lobby metadata has changed
func _on_lobby_data_update(this_lobby_id: int, member_id: int, key: int) -> void:
	print("Success, lobby ID: %s, member ID: %s, key: %s" % [this_lobby_id, member_id, key])


# When getting a lobby invitation
func _on_lobby_invite(inviter: int, this_lobby_id: int, game_id: int) -> void:
	get_node("%Output").add_new_text("You have received an invite from %s to join lobby %s / game %s" % [Steam.getFriendPersonaName(inviter), this_lobby_id, game_id])


# When a lobby is joined
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining succeed, this will be 1
	if response == 1:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		# Print the lobby ID to a label
		$Frame/Main/Displays/Outputs/Titles/Lobby.set_text("Lobby ID: %s" % lobby_id)
		# Append to output
		get_node("%Output").add_new_text("Joined lobby %s" % lobby_id)
		# Get the lobby members
		get_lobby_members()
		# Enable all necessary buttons
		change_button_controls(false)
		# Make the initial handshake
		make_p2p_handshake()
	# Else it failed for some reason
	else:
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
		get_node("%Output").add_new_text("Failed joining lobby %s: %s" % [lobby_id, fail_reason])
		# Reopen the server list
		_on_open_lobby_list_pressed()


# When accepting an invite
func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	var owner_name = Steam.getFriendPersonaName(friend_id)
	get_node("%Output").add_new_text("Joining %s's lobby..." % owner_name)
	# Attempt to join the lobby
	join_lobby(this_lobby_id)


#################################################
# P2P NETWORKING FUNCTIONS
#################################################
# Make a Steam P2P handshake so the other users get our details
func make_p2p_handshake() -> void:
	get_node("%Output").add_new_text("Sending P2P handshake to the lobby...")
	send_p2p_packet(0, {"message":"handshake", "from":Global.steam_id})


# P2P connection failure
func _on_p2p_session_connect_fail(steam_id: int, session_error: int) -> void:
	# Note the session errors are: 0 - none, 1 - target user not running the same game, 2 - local user doesn't own app, 3 - target user isn't connected to Steam, 4 - connection timed out, 5 - unused
		# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s [no error given]." % steam_id)
	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s [target user not running the same game]." % steam_id)
	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s [local user doesn't own app / game]." % steam_id)
	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s [target user isn't connected to Steam]." % steam_id)
	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s [connection timed out]." % steam_id)
	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s [unused]." % steam_id)
	# Else no known error
	else:
		print("WARNING: Session failure with %s [unknown error %s]" % [steam_id, session_error])


# When receiving a P2P request from another user
func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	# Print the debug message to output
	get_node("%Output").add_new_text("P2P session request from: %s" % this_requester)
	# Accept the P2P session; can apply logic to deny this request if needed
	var session_accepted: bool = Steam.acceptP2PSessionWithUser(remote_id)
	get_node("%Output").add_new_text("P2P session with %s was connected: %s" % [this_requester, session_accepted])
	# Make the initial handshake
	make_p2p_handshake()


func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	# There is a packet
	if packet_size > 0:
		print("There is a packet available.")
		# Get the packet
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
		# If it is empty, set a warning
		if this_packet.empty():
			print("[WARNING] Read an empty packet with non-zero size!")
		# Get the remote user's ID
		var packet_sender: String = str(this_packet['steam_id_remote'])
		var packet_code: PoolByteArray = this_packet['data']
		# Make the packet data readable
		var readable_packet: Dictionary = bytes2var(packet_code)
		# Print the packet to output
		get_node("%Output").add_new_text("Packet from %s: %s" % [packet_sender, readable_packet])
		# Append logic here to deal with packet data
		if readable_packet['message'] == "start":
			get_node("%Output").add_new_text("Starting P2P game...\n")


func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0
	# Create a data array to send the data through
	var this_packet_data: PoolByteArray = []
	this_packet_data.append_array(var2bytes(packet_data))
	# If sending a packet to everyone
	var send_response: bool
	if target == 0:
		# If there is more than one user, send packets
		if lobby_members.size() > 1:
			# Loop through all members that aren't you
			for this_member in lobby_members:
				if this_member['steam_id'] != Global.steam_id:
					send_response = Steam.sendP2PPacket(this_member['steam_id'], this_packet_data, send_type, channel)
	# Else send the packet to a particular user
	else:
		# Send this packet
		send_response = Steam.sendP2PPacket(target, this_packet_data, send_type, channel)
	# The packets send response is...?
	get_node("%Output").add_new_text("P2P packet sent successfully? %s" % send_response)


#################################################
# HELPER FUNCTIONS
#################################################
# Add a new Steam user to the connect users list
func add_to_player_list(steam_id: int, steam_name: String) -> void:
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
	print("Connecting kick_player signal to _on_lobby_kick for %s [%s]: %s" % [steam_name, steam_id, this_signal])
	# Add the child node
	$Frame/Main/Displays/PlayerList/Players.add_child(this_member)
	# If you are the host, enable the kick button
	if Global.steam_id == Steam.getLobbyOwner(lobby_id):
		get_node("Frame/Main/Displays/PlayerList/Players/%s/Member/Stuff/Controls/Kick" % this_member.name).set_disabled(false)


# Enable or disable a gang of buttons
func change_button_controls(toggle: bool) -> void:
	$Frame/Sidebar/Options/List/Leave.set_disabled(toggle)
	$Frame/Sidebar/Options/List/GetLobbyData.set_disabled(toggle)
	$Frame/Sidebar/Options/List/SendPacket.set_disabled(toggle)
	$Frame/Main/Messaging/Send.set_disabled(toggle)
	# Caveat for the lineedit
	if toggle:
		$Frame/Main/Messaging/Chat.set_editable(false)
	else:
		$Frame/Main/Messaging/Chat.set_editable(true)


# Get the lobby members from Steam
func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()
	# Clear the original player list
	for this_member in $Frame/Main/Displays/PlayerList/Players.get_children():
		this_member.hide()
		this_member.queue_free()
	# Get the number of members from this lobby from Steam
	var these_members: int = Steam.getNumLobbyMembers(lobby_id)
	# Update the player list title
	$Frame/Main/Displays/PlayerList/Title.set_text("Player List (%s)" % these_members)
	# Get the data of these players from Steam
	for this_member in range(0, these_members):
		print(this_member)
		# Get the member's Steam ID and name
		var member_steam_id: int = Steam.getLobbyMemberByIndex(Networking.lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		# Add them to the player list
		add_to_player_list(member_steam_id, member_steam_name)


# A user's information has changed
func _on_persona_change(steam_id: int, _flag: int) -> void:
	print("A user (%s) had information change, update the lobby list" % steam_id)
	# Update the player list
	get_lobby_members()


#################################################
# BUTTON FUNCTIONS
#################################################
# Creating a lobby
func _on_create_lobby_pressed() -> void:
	# Attempt to create a lobby
	_create_lobby()
	get_node("%Output").add_new_text("Attempt to create a new lobby...")
	# Disable the create lobby button
	$Frame/Sidebar/Options/List/CreateLobby.set_disabled(true)


# Getting associated metadata for the lobby
func _on_get_lobby_data_pressed() -> void:
	lobby_data = Steam.getLobbyData(lobby_id, "name")
	get_node("%Output").add_new_text("Lobby data, name: %s" % lobby_data)
	lobby_data = Steam.getLobbyData(lobby_id, "mode")
	get_node("%Output").add_new_text("Lobby data, mode: %s" % lobby_data)


# Sending a test packet out to the players
func _on_send_packet_pressed() -> void:
	get_node("%Output").add_new_text("Sending test packet data...\n")
	var test_data: Dictionary = {"title":"This is a test packet", "player_id":Global.steam_id, "player_hp":"5", "player_coord":"56,40"}
	send_p2p_packet(0, test_data)


#################################################
# LOBBY BROWSER FUNCTIONS
#################################################
func _on_close_lobbies_pressed() -> void:
	$Lobbies.hide()


# Getting a lobby match list
func _on_lobby_match_list(lobbies: Array) -> void:
	# Show the list
	for this_lobby in lobbies:
		# Pull lobby data from Steam
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")
		var lobby_nums: int = Steam.getNumLobbyMembers(this_lobby)
		# Create a button for the lobby
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_nums])
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.set_text_alignment(Button.ALIGN_LEFT)
		lobby_button.set_theme(button_theme)
		var lobby_signal: int = lobby_button.connect("pressed", self, "join_lobby", [this_lobby])
		print("Connecting pressed to function join_lobby for %s successfully: %s" % [this_lobby, lobby_signal])
		# Add the new lobby to the list
		$Lobbies/Scroll/List.add_child(lobby_button)
	# Enable the refresh button
	$Lobbies/Refresh.set_disabled(false)


# Open the lobby list
func _on_open_lobby_list_pressed() -> void:
	$Lobbies.show()
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# Request the list
	get_node("%Output").add_new_text("Requesting a lobby list...")
	Steam.requestLobbyList()


# Refresh the lobby list
func _on_refresh_pressed() -> void:
	# Clear all previous server entries
	for this_server in $Lobbies/Scroll/List.get_children():
		this_server.free()
	# Disable the refresh button
	$Lobbies/Refresh.set_disabled(true)
	# Set distance to world (or maybe change this option)
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# Request a new server list
	Steam.requestLobbyList()


#################################################
# LOBBY CHAT FUNCTIONS
#################################################
# Send the message by pressing enter
func _input(this_event: InputEvent) -> void:
	if this_event.is_pressed() and not this_event.is_echo() and not this_event.is_action("chat_send"):
		_on_send_chat_pressed()


func _on_chat_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		$Frame/Main/Messaging/Send.set_disabled(false)
	else:
		$Frame/Main/Messaging/Send.set_disabled(true)


func _on_chat_text_entered(new_text: String) -> void:
	if new_text.length() > 0:
		_on_send_chat_pressed()
	else:
		$Frame/Main/Messaging/Send.set_disabled(true)


func _on_lobby_chat_update(this_lobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	# Note that chat state changes is: 1 - entered, 2 - left, 4 - user disconnected before leaving, 8 - user was kicked, 16 - user was banned
	print("Lobby ID: %s, changed ID: %s, making change: %s, chat state: %s" % [this_lobby_id, changed_id, making_change_id,chat_state])
	# Get the user who has made the lobby change
	var this_changer = Steam.getFriendPersonaName(changed_id)
	# If a player has joined the lobby
	if chat_state == 1:
		get_node("%Output").add_new_text("%s has joined the lobby" % this_changer)
	# Else if a player has left the lobby
	elif chat_state == 2:
		get_node("%Output").add_new_text("%s has left the lobby" % this_changer)
	# Else if a player has been kicked
	elif chat_state == 8:
		get_node("%Output").add_new_text("%s has been kicked from the lobby" % this_changer)
	# Else if a player has been banned
	elif chat_state == 16:
		get_node("%Output").add_new_text("%s has been banned from the lobby" % this_changer)
	# Else there was some unknown change
	else:
		get_node("%Output").add_new_text("%s did... something" % this_changer)
	# Update the lobby now that a change has occurred
	get_lobby_members()


func _on_lobby_kick(kick_id: int) -> void:
	# Pass the kick message to Steam
	var is_sent: bool = Steam.sendLobbyChatMsg(lobby_id, "/kick:%s" % kick_id)
	# Was it send successfully?
	if not is_sent:
		print("[ERROR] Kick command failed to send.\n")


# When a lobby message is received
# Using / delimiter for host commands like kick
func _on_lobby_message(_result: int, user: int, message: String, type: int) -> void:
	# We are only concerned with who is sending the message and what the message is
	var this_sender = Steam.getFriendPersonaName(user)
	# If this is a message or host command
	if type == 1:
		# If the lobby owner and the sender are the same, check for commands
		if user == Steam.getLobbyOwner(lobby_id) and message.begins_with("/"):
			print("Message sender is the lobby owner.")
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
			print("%s says '%s'" % [this_sender, message])
			get_node("%Output").add_new_text("%s says '%s'" % [this_sender, message])
	# Else this is a different type of message
	else:
		match type:
			2: get_node("%Output").add_new_text("%s is typing..." % this_sender)
			3: get_node("%Output").add_new_text("%s sent an invite that won't work in this chat" % this_sender)
			4: get_node("%Output").add_new_text("%s sent a text emote that is deprecated" % this_sender)
			6: get_node("%Output").add_new_text("%s has left the chat" % this_sender)
			7: get_node("%Output").add_new_text("%s has entered the chat" % this_sender)
			8: get_node("%Output").add_new_text("%s was kicked" % this_sender)
			9: get_node("%Output").add_new_text("%s was banned" % this_sender)
			10: get_node("%Output").add_new_text("%s disconnected" % this_sender)
			11: get_node("%Output").add_new_text("%s sent an old, offline message" % this_sender)
			12: get_node("%Output").add_new_text("%s sent a link that was removed by the chat filter" % this_sender)


func _on_send_chat_pressed() -> void:
	var this_message: String = $Frame/Main/Messaging/Chat.get_text()
	if this_message.length() > 0:
		var is_sent: bool = Steam.sendLobbyChatMsg(lobby_id, this_message)
		if not is_sent:
			get_node("%Output").add_new_text("[ERROR] Chat message '%s' failed to send" % this_message)
		$Frame/Main/Messaging/Chat.clear()


#################################################
# COMMAND LINE ARGUMENTS
#################################################
# Check the command line for arguments
# Used primarily if a player accepts an invite and does not have the game opened
func check_command_line() -> void:
	var these_arguments = OS.get_cmdline_args()
	# There are arguments to process
	if these_arguments.size() > 0:
		# There is a connect lobby argument
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))


#################################################
# HELPER FUNCTIONS
#################################################
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


func _on_back_pressed() -> void:
	# Leave the lobby if in one
	if lobby_id > 0:
		_on_leave_lobby_pressed()
	Loading.load_scene("main")

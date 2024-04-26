extends Panel
#################################################
# LOBBY EXAMPLE
#################################################


enum LOBBY_AVAILABILITY { PRIVATE, FRIENDS, PUBLIC, INVISIBLE }

var lobby_id: int = 0
var lobby_members: Array = []
var lobby_max_members: int = 10

@onready var button_theme = preload("res://data/themes/button-theme.tres")
@onready var lobby_member_scene = preload("res://src/examples/lobby-member.tscn")

@onready var output: RichTextLabel = $Frame/Main/Displays/Outputs/Output

@onready var button_create_lobby: Button = $Frame/Sidebar/Options/List/CreateLobby
@onready var label_lobby_id: Label = $"Frame/Main/Displays/Outputs/Titles/Lobby ID"
@onready var button_get_lobby_data: Button = $Frame/Sidebar/Options/List/GetLobbyData
@onready var button_leave: Button = $Frame/Sidebar/Options/List/Leave
@onready var button_send_packet: Button = $Frame/Sidebar/Options/List/SendPacket
@onready var button_send_message: Button = $Frame/Main/Messaging/Send

@onready var chat_input: LineEdit = $Frame/Main/Messaging/Chat

@onready var player_list_title: Label = $Frame/Main/Displays/PlayerList/Title
@onready var player_list_vbox: VBoxContainer = $Frame/Main/Displays/PlayerList/Players

@onready var lobbies_panel: Panel = $Lobbies
@onready var button_lobbies_refresh: Button = $Lobbies/Refresh
@onready var lobbies_list_vbox: VBoxContainer = $Lobbies/Scroll/List


func _ready() -> void:
	Helper.connect_signal(Steam.lobby_created, _on_lobby_created)
	Helper.connect_signal(Steam.lobby_match_list, _on_lobby_match_list)
	Helper.connect_signal(Steam.lobby_joined, _on_lobby_joined)
	Helper.connect_signal(Steam.lobby_chat_update, _on_lobby_chat_update)
	Helper.connect_signal(Steam.lobby_message, _on_lobby_message)
	Helper.connect_signal(Steam.lobby_data_update, _on_lobby_data_update)
	Helper.connect_signal(Steam.lobby_invite, _on_lobby_invite)
	Helper.connect_signal(Steam.join_requested, _on_lobby_join_requested)
	Helper.connect_signal(Steam.persona_state_change, _on_persona_change)
	Helper.connect_signal(Steam.p2p_session_request, _on_p2p_session_request)
	Helper.connect_signal(Steam.p2p_session_connect_fail, _on_p2p_session_connect_fail)
	
	# Check for command line arguments
	check_command_line()


func _process(_delta: float) -> void:
	# Get packets only if lobby is joined
	if lobby_id > 0:
		read_p2p_packet()


# Send the message by pressing enter
func _input(ev: InputEvent) -> void:
	if ev.is_pressed() and !ev.is_echo() and ev.is_action("chat_send"):
		_on_send_chat_pressed()


func _on_back_pressed() -> void:
	if lobby_id > 0:
		leave_lobby()


#################################################
# LOBBY FUNCTIONS
#################################################

# Creating a lobby
func _on_create_lobby_pressed() -> void:
	# Attempt to create a lobby
	create_lobby()
	output.append_text("[STEAM] Attempt to create a new lobby...\n")
	# Disable the create lobby button
	button_create_lobby.set_disabled(true)


# Getting associated metadata for the lobby
func _on_get_lobby_data_pressed() -> void:
	var data
	data = Steam.getLobbyData(lobby_id, "name")
	output.append_text("[STEAM] Lobby data, name: "+str(data)+"\n")
	data = Steam.getLobbyData(lobby_id, "mode")
	output.append_text("[STEAM] Lobby data, mode: "+str(data)+"\n")


# Leaving the lobby
func _on_leave_lobby_pressed() -> void:
	leave_lobby()


# When the user starts a game with multiplayer enabled
func create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobby_id == 0:
		# Set the lobby to public with ten members max
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_max_members)


# When the player is joining a lobby
func join_lobby(_lobby_id: int) -> void:
	lobby_id = _lobby_id
	output.append_text("[STEAM] Attempting to join lobby "+str(lobby_id)+"...\n")
	# Close lobby panel if open
	_on_close_lobbies_pressed()
	# Clear any previous lobby lists
	lobby_members.clear()
	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)


func _on_lobby_kick_pressed(kick_id: int) -> void:
	# Pass the kick message to Steam
	var IS_SENT: bool = Steam.sendLobbyChatMsg(lobby_id, "/kick:"+str(kick_id))
	# Was it send successfully?
	if not IS_SENT:
		print("[ERROR] Kick command failed to send.\n")


# When the player leaves a lobby for whatever reason
func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Append a new message
		output.append_text("[STEAM] Leaving lobby "+str(lobby_id)+".\n")
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)
		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0

		label_lobby_id.set_text("Lobby ID: "+str(lobby_id))
		player_list_title.set_text("Player List (0)")
		# Close session with all users
		for MEMBERS in lobby_members:
			var SESSION_CLOSED: bool = Steam.closeP2PSessionWithUser(MEMBERS['steam_id'])
			print("[STEAM] P2P session closed with "+str(MEMBERS['steam_id'])+": "+str(SESSION_CLOSED))
		# Clear the local lobby list
		lobby_members.clear()
		for player in player_list_vbox.get_children():
			player.hide()
			player.queue_free()
		# Enable the create lobby button
		button_create_lobby.set_disabled(false)
		# Disable the leave lobby button and all test buttons
		change_button_states(true)


# Get the lobby members from Steam
func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()
	# Clear the original player list
	for MEMBER in $Frame/Main/Displays/PlayerList/Players.get_children():
		MEMBER.hide()
		MEMBER.queue_free()
	# Get the number of members from this lobby from Steam
	var MEMBERS: int = Steam.getNumLobbyMembers(lobby_id)
	# Update the player list title
	$Frame/Main/Displays/PlayerList/Title.set_text("Player List ("+str(MEMBERS)+")")
	# Get the data of these players from Steam
	for MEMBER in range(0, MEMBERS):
		print(MEMBER)
		# Get the member's Steam ID
		var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(lobby_id, MEMBER)
		# Get the member's Steam name
		var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		# Add them to the player list
		add_player_to_connect_list(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)


#################################################
# P2P NETWORKING FUNCTIONS
#################################################

# Make a Steam P2P handshake so the other users get our details
func make_p2p_handshake() -> void:
	output.append_text("[STEAM] Sending P2P handshake to the lobby...\n")
	send_p2p_packet(0, {"message":"handshake", "from":Global.steam_id})


# Send test packet information
func send_test_info() -> void:
	output.append_text("[STEAM] Sending test packet data...\n")
	var TEST_DATA: Dictionary = {"title":"This is a test packet", "player_id":Global.steam_id, "player_hp":"5", "player_coord":"56,40"}
	send_p2p_packet(0, TEST_DATA)


func read_p2p_packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)
	# There is a packet
	if PACKET_SIZE > 0:
		print("[STEAM] There is a packet available.")
		# Get the packet
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)
		# If it is empty, set a warning
		if PACKET.is_empty():
			print("[WARNING] Read an empty packet with non-zero size!")
		# Get the remote user's ID
		var PACKET_SENDER: String = str(PACKET['steam_id_remote'])
		var PACKET_CODE: PackedByteArray = PACKET['data']
		# Make the packet data readable
		var READABLE: Dictionary = bytes_to_var(PACKET_CODE)
		# Print the packet to output
		output.append_text("[STEAM] Packet from "+str(PACKET_SENDER)+": "+str(READABLE)+"\n")
		# Append logic here to deal with packet data
		if READABLE['message'] == "start":
			output.append_text("[STEAM] Starting P2P game...\n")


func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var SEND_TYPE: int = Steam.P2P_SEND_RELIABLE
	var CHANNEL: int = 0
	# Create a data array to send the data through
	var PACKET_DATA: PackedByteArray = []
	PACKET_DATA.append_array(var_to_bytes(packet_data))
	# If sending a packet to everyone
	var SEND_RESPONSE: bool
	if target == 0:
		# If there is more than one user, send packets
		if lobby_members.size() > 1:
			# Loop through all members that aren't you
			for MEMBER in lobby_members:
				if MEMBER['steam_id'] != Global.steam_id:
					SEND_RESPONSE = Steam.sendP2PPacket(MEMBER['steam_id'], PACKET_DATA, SEND_TYPE, CHANNEL)
	# Else send the packet to a particular user
	else:
		# Send this packet
		SEND_RESPONSE = Steam.sendP2PPacket(target, PACKET_DATA, SEND_TYPE, CHANNEL)
	# The packets send response is...?
	output.append_text("[STEAM] P2P packet sent successfully? "+str(SEND_RESPONSE)+"\n")


#################################################
# HELPER FUNCTIONS
#################################################

# Add a new Steam user to the connect users list
func add_player_to_connect_list(steam_id: int, steam_name: String) -> void:
	print("Adding new player to the list: "+str(steam_id)+" / "+str(steam_name))
	# Add them to the list
	lobby_members.append({"steam_id":steam_id, "steam_name":steam_name})
	# Instance the lobby member object
	var lobby_member: LobbyMember = lobby_member_scene.instantiate()
	# Add their Steam name and ID
	lobby_member.name = str(steam_id)
	lobby_member.set_member(steam_id, steam_name)
	# Connect the kick signal
	Helper.connect_signal(lobby_member.kick_player, _on_lobby_kick_pressed)
	player_list_vbox.add_child(lobby_member)
	
	# If you are the host, enable the kick button
	if Global.steam_id == Steam.getLobbyOwner(lobby_id):
		lobby_member.button_kick.set_disabled(false)
	else:
		lobby_member.button_kick.set_disabled(true)


# Enable or disable a gang of buttons
func change_button_states(toggle: bool) -> void:
	button_leave.set_disabled(toggle)
	button_get_lobby_data.set_disabled(toggle)
	button_send_packet.set_disabled(toggle)
	button_send_message.set_disabled(toggle)
	# Caveat for the lineedit
	if toggle:
		chat_input.set_editable(false)
	else:
		chat_input.set_editable(true)


# Sending a test packet out to the players
func _on_send_packet_pressed() -> void:
	send_test_info()


#################################################
# LOBBY BROWSER
#################################################


func _on_close_lobbies_pressed() -> void:
	lobbies_panel.hide()


# Open the lobby list
func _on_open_lobby_list_pressed() -> void:
	lobbies_panel.show()
	# Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# Request the list
	output.append_text("[STEAM] Requesting a lobby list...\n")
	Steam.requestLobbyList()


# Refresh the lobby list
func _on_refresh_pressed() -> void:
	# Clear all previous server entries
	for server in lobbies_list_vbox.get_children():
		server.free()
	# Disable the refresh button
	button_lobbies_refresh.set_disabled(true)
	# Set distance to world (or maybe change this option)
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# Request a new server list
	Steam.requestLobbyList()


#################################################
# LOBBY CHAT
#################################################


# Send a chat message
func _on_send_chat_pressed() -> void:
	# Get the entered chat message
	var MESSAGE: String = $Frame/Main/Messaging/Chat.get_text()
	# If there is even a message
	if MESSAGE.length() > 0:
		# Pass the message to Steam
		var IS_SENT: bool = Steam.sendLobbyChatMsg(lobby_id, MESSAGE)
		# Was it sent successfully?
		if not IS_SENT:
			output.append_text("[ERROR] Chat message '"+str(MESSAGE)+"' failed to send.\n")
		# Clear the chat input
		$Frame/Main/Messaging/Chat.clear()


# Using / delimiter for host commands like kick
func process_lobby_message(_result: int, user: int, message: String, type: int):
# We are only concerned with who is sending the message and what the message is
	var SENDER = Steam.getFriendPersonaName(user)
	# If this is a message or host command
	if type == 1:
		# If the lobby owner and the sender are the same, check for commands
		if user == Steam.getLobbyOwner(lobby_id) and message.begins_with("/"):
			print("Message sender is the lobby owner.")
			# Get any commands
			if message.begins_with("/kick"):
				# Get the user ID for kicking
				var COMMANDS: PackedStringArray = message.split(":", true)
				# If this is your ID, leave the lobby
				if Global.steam_id == int(COMMANDS[1]):
					leave_lobby()
		# Else this is just chat message
		else:
			# Print the outpubt before showing the message
			print(str(SENDER)+" says: "+str(message))
			output.append_text(str(SENDER)+" says '"+str(message)+"'\n")
	# Else this is a different type of message
	else:
		match type:
			2: output.append_text(str(SENDER)+" is typing...\n")
			3: output.append_text(str(SENDER)+" sent an invite that won't work in this chat!\n")
			4: output.append_text(str(SENDER)+" sent a text emote that is deprecated.\n")
			6: output.append_text(str(SENDER)+" has left the chat.\n")
			7: output.append_text(str(SENDER)+" has entered the chat.\n")
			8: output.append_text(str(SENDER)+" was kicked!\n")
			9: output.append_text(str(SENDER)+" was banned!\n")
			10: output.append_text(str(SENDER)+" disconnected.\n")
			11: output.append_text(str(SENDER)+" sent an old, offline message.\n")
			12: output.append_text(str(SENDER)+" sent a link that was removed by the chat filter.\n")


#################################################
# CALLBACKS
#################################################

# When a lobby chat is updated
func _on_lobby_chat_update(lobby_id: int, changed_id: int, making_change_id: int, chat_state: int) -> void:
	# Note that chat state changes is: 1 - entered, 2 - left, 4 - user disconnected before leaving, 8 - user was kicked, 16 - user was banned
	print("[STEAM] Lobby ID: "+str(lobby_id)+", Changed ID: "+str(changed_id)+", Making Change: "+str(making_change_id)+", Chat State: "+str(chat_state))
	# Get the user who has made the lobby change
	var CHANGER = Steam.getFriendPersonaName(changed_id)
	# If a player has joined the lobby
	if chat_state == 1:
		output.append_text("[STEAM] "+str(CHANGER)+" has joined the lobby.\n")
	# Else if a player has left the lobby
	elif chat_state == 2:
		output.append_text("[STEAM] "+str(CHANGER)+" has left the lobby.\n")
	# Else if a player has been kicked
	elif chat_state == 8:
		output.append_text("[STEAM] "+str(CHANGER)+" has been kicked from the lobby.\n")
	# Else if a player has been banned
	elif chat_state == 16:
		output.append_text("[STEAM] "+str(CHANGER)+" has been banned from the lobby.\n")
	# Else there was some unknown change
	else:
		output.append_text("[STEAM] "+str(CHANGER)+" did... something.\n")
	# Update the lobby now that a change has occurred
	get_lobby_members()


# When receiving a P2P request from another user
func _on_p2p_session_request(remoteID: int) -> void:
	# Get the requester's name
	var REQUESTER: String = Steam.getFriendPersonaName(remoteID)
	# Print the debug message to output
	output.append_text("[STEAM] P2P session request from "+str(REQUESTER)+"\n")
	# Accept the P2P session; can apply logic to deny this request if needed
	var SESSION_ACCEPTED: bool = Steam.acceptP2PSessionWithUser(remoteID)
	output.append_text("[STEAM] P2P session was connected: "+str(SESSION_ACCEPTED)+"\n")
	# Make the initial handshake
	make_p2p_handshake()


# P2P connection failure
func _on_p2p_session_connect_fail(lobby_id: int, session_error: int) -> void:
	# Note the session errors are: 0 - none, 1 - target user not running the same game, 2 - local user doesn't own app, 3 - target user isn't connected to Steam, 4 - connection timed out, 5 - unused
	# If no error was given
	if session_error == 0:
		print("[WARNING] Session failure with "+str(lobby_id)+" [no error given].")
	# Else if target user was not running the same game
	elif session_error == 1:
		print("[WARNING] Session failure with "+str(lobby_id)+" [target user not running the same game].")
	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("[WARNING] Session failure with "+str(lobby_id)+" [local user doesn't own app / game].")
	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("[WARNING] Session failure with "+str(lobby_id)+" [target user isn't connected to Steam].")
	# Else if connection timed out
	elif session_error == 4:
		print("[WARNING] Session failure with "+str(lobby_id)+" [connection timed out].")
	# Else if unused
	elif session_error == 5:
		print("[WARNING] Session failure with "+str(lobby_id)+" [unused].")
	# Else no known error
	else:
		print("[WARNING] Session failure with "+str(lobby_id)+" [unknown error "+str(session_error)+"].")


# When a lobby message is received
func _on_lobby_message(_result: int, user: int, message: String, type: int) -> void:
	process_lobby_message(_result, user, message, type)


# Getting a lobby match list
func _on_lobby_match_list(lobbies: Array) -> void:
	# Show the list 
	for lobby_id in lobbies:
		# Pull lobby data from Steam
		var lobby_name: String = Steam.getLobbyData(lobby_id, "name")
		var lobby_mode: String = Steam.getLobbyData(lobby_id, "mode")
		var lobby_member_count: int = Steam.getNumLobbyMembers(lobby_id)
		# Create a button for the lobby
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby "+str(lobby_id)+": "+str(lobby_name)+" ["+str(lobby_mode)+"] - "+str(lobby_member_count)+" Player(s)")
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_"+str(lobby_id))
		lobby_button.set_text_alignment(HORIZONTAL_ALIGNMENT_LEFT)
		lobby_button.set_theme(button_theme)
		lobby_button.pressed.connect(join_lobby.bind(lobby_id))
		# Add the new lobby to the list
		$Lobbies/Scroll/List.add_child(lobby_button)
	# Enable the refresh button
	$Lobbies/Refresh.set_disabled(false)



# A lobby has been successfully created
func _on_lobby_created(connect_result: int, _lobby_id: int) -> void:
	if connect_result == 1:
		lobby_id = _lobby_id
		
		output.append_text("[STEAM] Created a lobby: "+str(lobby_id)+"\n")

		# Set lobby joinable as a test
		var SET_JOINABLE: bool = Steam.setLobbyJoinable(lobby_id, true)
		print("[STEAM] The lobby has been set joinable: "+str(SET_JOINABLE))

		# Print the lobby ID to a label
		label_lobby_id.text = "Lobby ID: " + str(lobby_id)

		# Set some lobby data
		var SET_LOBBY_DATA: bool = false
		SET_LOBBY_DATA = Steam.setLobbyData(lobby_id, "name", str(Global.steam_username)+"'s Lobby")
		print("[STEAM] Setting lobby name data successful: "+str(SET_LOBBY_DATA))
		SET_LOBBY_DATA = Steam.setLobbyData(lobby_id, "mode", "GodotSteam test")
		print("[STEAM] Setting lobby mode data successful: "+str(SET_LOBBY_DATA))

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var IS_RELAY: bool = Steam.allowP2PPacketRelay(true)
		output.append_text("[STEAM] Allowing Steam to be relay backup: "+str(IS_RELAY)+"\n")

		# Enable the leave lobby button and all testing buttons
		change_button_states(false)
	else:
		output.append_text("[STEAM] Failed to create lobby\n")


# Whan lobby metadata has changed
func _on_lobby_data_update(lobby_id: int, memberID: int, key: int) -> void:
	print("[STEAM] Success, Lobby ID: "+str(lobby_id)+", Member ID: "+str(memberID)+", Key: "+str(key)+"\n\n")


# When a lobby is joined
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining succeed, this will be 1
	if response == 1:
		# Set this lobby ID as your lobby ID
		lobby_id = lobby_id
		# Print the lobby ID to a label
		label_lobby_id.text = "Lobby ID: " + str(lobby_id)
		# Append to output
		output.append_text("[STEAM] Joined lobby "+str(lobby_id)+".\n")
		# Get the lobby members
		get_lobby_members()
		# Enable all necessary buttons
		change_button_states(false)
		# Make the initial handshake
		make_p2p_handshake()
	# Else it failed for some reason
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2:	FAIL_REASON = "This lobby no longer exists."
			3:	FAIL_REASON = "You don't have permission to join this lobby."
			4:	FAIL_REASON = "The lobby is now full."
			5:	FAIL_REASON = "Uh... something unexpected happened!"
			6:	FAIL_REASON = "You are banned from this lobby."
			7:	FAIL_REASON = "You cannot join due to having a limited account."
			8:	FAIL_REASON = "This lobby is locked or disabled."
			9:	FAIL_REASON = "This lobby is community locked."
			10:	FAIL_REASON = "A user in the lobby has blocked you from joining."
			11:	FAIL_REASON = "A user you have blocked is in the lobby."
		output.append_text("[STEAM] Failed joining lobby "+str(lobby_id)+": "+str(FAIL_REASON)+"\n")
		# Reopen the server list
		_on_open_lobby_list_pressed()


# When getting a lobby invitation
func _on_lobby_invite(inviter: int, lobby_id: int, game_id: int) -> void:
	output.append_text("[STEAM] You have received an invite from "+str(Steam.getFriendPersonaName(inviter))+" to join lobby "+str(lobby_id)+" / game "+str(game_id)+"\n")


# When accepting an invite
func _on_lobby_join_requested(lobby_id: int, friend_id: int) -> void:
	# Get the lobby owner's name
	var OWNER_NAME = Steam.getFriendPersonaName(friend_id)
	output.append_text("[STEAM] Joining "+str(OWNER_NAME)+"'s lobby...\n")
	# Attempt to join the lobby
	join_lobby(lobby_id)


# A user's information has changed
func _on_persona_change(steam_id: int, _flag: int) -> void:
	print("[STEAM] A user ("+str(steam_id)+") had information change, update the lobby list")
	# Update the player list
	get_lobby_members()


#################################################
# COMMAND LINE ARGUMENTS
#################################################

# Check the command line for arguments
# Used primarily if a player accepts an invite and does not have the game opened
func check_command_line():
	var ARGUMENTS = OS.get_cmdline_args()
	# There are arguments to process
	if ARGUMENTS.size() > 0:
		# There is a connect lobby argument
		if ARGUMENTS[0] == "+connect_lobby":
			if int(ARGUMENTS[1]) > 0:
				print("CMD Line Lobby ID: "+str(ARGUMENTS[1]))
				join_lobby(int(ARGUMENTS[1]))

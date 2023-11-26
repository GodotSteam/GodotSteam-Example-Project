extends Node
#################################################
# NETWORKING GLOBAL SCRIPT
#################################################
enum channels {HOST, CLIENT, VOICE}

var connected_players: Array = []
var connection_handle: int = 0
var host_id: int = 0
var host_identity: String = ""
var is_connected: bool = false
var is_host: bool = false
var lobby_id: int = 0
var lobby_members: Array = []
var packet_read_limit: int = 32
var send_channel: int = 0

signal make_p2p_handshake
# Define signals for your different kinds of messages here
signal movement(payload)
signal start_game(payload)


func _ready() -> void:
	Steam.initRelayNetworkAccess()
	# These signals are broken up into their respective networking classes
	# The three main types, networking, networking messages, and networking sockets, are different
	# networking systems; used separately from each other.
	# Networking class
	connect_steam_signals("p2p_session_request", "_on_p2p_session_request")
	connect_steam_signals("p2p_session_connect_fail", "_on_p2p_session_connect_fail")
	# Networking Messages class
	connect_steam_signals("network_messages_session_request", "_on_network_messages_session_request")
	connect_steam_signals("network_messages_session_failed", "_on_network_messages_session_failed")


func _process(_delta: float) -> void:
	if is_connected:
		read_p2p_packet()


#################################################
# LOBBY FUNCTIONS
#################################################
func clear_lobby_data() -> void:
	lobby_id = 0


#################################################
# P2P NETWORKING FUNCTIONS
# These are currently deprecated
# But they will always work with any SDK version that has this class
#################################################
func _on_p2p_session_connect_fail(steam_id: int, session_error: int) -> void:
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


func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("P2P session request from: %s" % this_requester)
	# Accept the P2P session; can apply logic to deny this request if needed
	if not Steam.acceptP2PSessionWithUser(remote_id):
		print("Failed to accept P2P session from: %s (%s)" % [this_requester, remote_id])
	# Make the initial handshake
	emit_signal("make_p2p_handshake")


func read_p2p_packet() -> void:
		var packet_size: int = Steam.getAvailableP2PPacketSize(0)
		# There is a packet
		if packet_size > 0:
			var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
			if this_packet.empty() or this_packet == null:
				print("WARNING: read an empty packet with non-zero size!")

			# Get the remote user's ID
			var packet_sender: int = this_packet['steam_id_remote']
			print("Packet sent by: %s" % packet_sender)

			# Make the packet data readable
			var readable_data: Dictionary = bytes2var(this_packet['data'].decompress_dynamic(-1, File.COMPRESSION_GZIP))
			# Print the packet to output
			print("Packet: "+str(readable_data))


func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
		# Set the send_type and channel
		var send_type: int = Steam.P2P_SEND_RELIABLE
		if is_host:
			send_channel = channels.HOST
		else:
			send_channel = channels.CLIENT

		# Create a data array to send the data through
		var this_data: PoolByteArray = []
		# Compress the PoolByteArray we create from our dictionary  using the GZIP compression method
		var compressed_data: PoolByteArray = var2bytes(packet_data).compress(File.COMPRESSION_GZIP)
		this_data.append_array(compressed_data)

		# If sending a packet to everyone
		if target == 0:
			# If there is more than one user, send packets
			if connected_players.size() > 1:
				# Loop through all members that aren't you
				for this_player in connected_players:
					if this_player['steam_id'] != Global.steam_id:
						if not Steam.sendP2PPacket(this_player['steam_id'], this_data, send_type, send_channel):
							print("[ERROR] Failed to send P2P packet to user %s" % this_player['steam_id'])
		# Else send it to someone specific
		else:
			if not Steam.sendP2PPacket(target, this_data, send_type, send_channel):
				print("[ERROR] Failed to send P2P packet to user %s" % target)


#################################################
# NETWORKING MESSAGES FUNCTIONS
# Newer networking messages class
#################################################
func _on_network_messages_session_failed(reason: int) -> void:
	print("[ERROR] Network messages session failed, reason: %s" % reason)


# Add this user to your identity list
func _on_network_messages_session_request(this_identity: String) -> void:
	var this_id: String = this_identity.split(':', true)[1]

	if int(this_id) != Global.steam_id:
		if Steam.addIdentity(this_identity):
			Steam.setIdentitySteamID(this_identity, int(this_id))
			if Steam.acceptSessionWithUser(this_identity):
				print("Accepting session with %s" % this_identity)
			else:
				print("[ERROR] Failed to accept session with: %s" % this_identity)
		else:
			print("[ERROR] Failed to add identity: %s" % this_identity)


# Read in messages and emit the signal type
# As messages come in, we can apply basic authentication on structure, etc.
# Before emitting a signal with the body of the message for those interested
# To unpack/do something useful with
func read_p2p_messages() -> void:
	var these_messages: Array = Steam.receiveMessagesOnChannel(0, 16)
	for this_message in these_messages:
		print("[DEBUG] Raw Steam msg %s" % this_message)
		var decoded_message = bytes2var(this_message['payload'].decompress_dynamic(-1, File.COMPRESSION_GZIP))
		print("[DEBUG] Decoded Steam message %s" % decoded_message)
		if "type" in decoded_message:
			# emit a signal with the same name as the type and let subscribers parse it
			emit_signal(decoded_message['type'], decoded_message)


# Send a message to a user. Specify the intended target by passing in their identity reference name
func send_p2p_message(this_target: String, this_data: Dictionary) -> void:
	var packet_data: PoolByteArray = []
	packet_data.append_array(var2bytes(this_data).compress(File.COMPRESSION_GZIP))
	if this_target == "":
		for this_identity in Steam.getIdentities():
			if Steam.isIdentityInvalid(this_identity['reference_name']):
				print("[ERROR] This identity is invald, message will not be sent")
			else:
				# Don't send to ourselves
				if this_identity['steam_id'] != Global.steam_id:
					if not Steam.sendMessageToUser(this_identity['reference_name'], packet_data, Steam.NETWORKING_SEND_RELIABLE, send_channel) == Steam.RESULT_OK:
						print("[ERROR] Failed to send P2P message")
#				else:
#					print("Not sending message to self")
	else:
		if not Steam.sendMessageToUser(this_target, packet_data, Steam.NETWORKING_SEND_RELIABLE, send_channel) == Steam.RESULT_OK:
			print("[ERROR] Failed to send P2P message")


#################################################
# HELPER FUNCTIONS
#################################################
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


func is_player_the_host() -> void:
	if lobby_id > 0:
		var lobby_owner: int = Steam.getLobbyOwner(lobby_id)
		if lobby_owner == Global.steam_id:
			print("Local player is the host")
			is_host = true
		else:
			is_host = false
	else:
		print("[ERROR] The player is not in a lobby")

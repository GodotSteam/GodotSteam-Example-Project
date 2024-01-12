extends Panel
#################################################
# AUTHENICATION EXAMPLE
#################################################
var auth_ticket: Dictionary		# Your auth ticket
var client_auth_tickets: Array	# Array of clients tickets


func _ready() -> void:
	connect_steam_signals("get_auth_session_ticket_response", "_on_get_auth_session_ticket_response")
	connect_steam_signals("validate_auth_ticket_response", "_on_validate_auth_ticket_response")


func _on_begin_auth_session_pressed() -> void:
	if auth_ticket.has('buffer') and auth_ticket.has('size'):
		var auth_response: int = Steam.beginAuthSession(auth_ticket['buffer'], auth_ticket['size'], Global.steam_id)
		# Get a verbose response
		var verbose_response: String
		match auth_response:
			0: verbose_response = "Ticket is valid for this game and this Steam ID."
			1: verbose_response = "The ticket is invalid."
			2: verbose_response = "A ticket has already been submitted for this Steam ID."
			3: verbose_response = "Ticket is from an incompatible interface version."
			4: verbose_response = "Ticket is not for this game."
			5: verbose_response = "Ticket has expired."
		get_node("%Output").add_new_text("Auth verifcation response: %s\n" % verbose_response)
	
		# If successful, add this client to the list
		if auth_response == 0:
			client_auth_tickets.append({"id": Global.steam_id, "ticket": auth_ticket['id']})
			# Allow the client to join the game
	else:
		get_node("%Output").add_new_text("There is no current or valid auth ticket")


# Callback from getting the auth ticket from Steam
func _on_get_auth_session_ticket_response(this_auth_ticket: int, this_result: int) -> void:
	get_node("%Output").add_new_text("Auth session result: %s" % this_result)
	get_node("%Output").add_new_text("Auth session ticket handle: %s\n" % this_auth_ticket)


# Request an auth ticket from Steam
func _on_get_auth_ticket_pressed() -> void:
	auth_ticket = Steam.getAuthSessionTicket("")
	get_node("%Output").add_new_text("Auth Ticket: %s\n" % auth_ticket)


# Callback from attempting to validate the auth ticket
func _on_validate_auth_ticket_response(auth_id: int, response: int, owner_id: int) -> void:
	get_node("%Output").add_new_text("Ticket owner: %s" % auth_id)
	# Make the response more verbose
	var verbose_response: String
	match response:
		0: verbose_response = "Steam has verified the user is online, the ticket is valid and ticket has not been reused."
		1: verbose_response = "The user in question is not connected to Steam."
		2: verbose_response = "The user doesn't have a license for this app ID or the ticket has expired."
		3: verbose_response = "The user is VAC banned for this game."
		4: verbose_response = "The user account has logged in elsewhere and the session containing the game instance has been disconnected."
		5: verbose_response = "VAC has been unable to perform anti-cheat checks on this user."
		6: verbose_response = "The ticket has been canceled by the issuer."
		7: verbose_response = "This ticket has already been used, it is not valid."
		8: verbose_response = "This ticket is not from a user instance currently connected to steam."
		9: verbose_response = "The user is banned for this game. The ban came via the web API and not VAC."
	get_node("%Output").add_new_text("Auth response: %s" % verbose_response)
	get_node("%Output").add_new_text("Game owner ID: %s\n" % owner_id)


# Send your auth ticket to the other client or server
func _send_Auth_Ticket() -> void:
	pass


#################################################
# ENDING AUTH SESSION FUNCTIONS
#################################################
func _on_cancel_auth_ticket_pressed() -> void:
	if auth_ticket.has('id'):
		Steam.cancelAuthTicket(auth_ticket['id'])
		get_node("%Output").add_new_text("Canceling your auth ticket...\n")
	else:
		get_node("%Output").add_new_text("There is no current or valid auth ticket")


func _on_end_auth_session_pressed() -> void:
	# Loop through all client tickets and close them out
	for this_client in client_auth_tickets:
		get_node("%Output").add_new_text("Ending auth session with %s\n" % this_client['id'])
		Steam.endAuthSession(this_client['id'])
		# Remove this client from the list
		client_auth_tickets.erase(this_client)


#################################################
# HELPER FUNCTIONS
#################################################
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


func _on_back_pressed() -> void:
	Loading.load_scene("main")

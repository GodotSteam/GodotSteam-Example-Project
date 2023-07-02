extends Panel
#################################################
# AUTHENICATION EXAMPLE
#################################################
var TICKET: Dictionary		# Your auth ticket
var CLIENT_TICKETS: Array	# Array of clients tickets


func _ready() -> void:
	_connect_Steam_Signals("get_auth_session_ticket_response", "_get_Auth_Session_Ticket_Response")
	_connect_Steam_Signals("validate_auth_ticket_response", "_validate_Auth_Ticket_Response")


# Callback from getting the auth ticket from Steam
func _get_Auth_Session_Ticket_Response(auth_ticket: int, result: int) -> void:
	$Frame/Main/Output.append_text("Auth session result: "+str(result)+"\n")
	$Frame/Main/Output.append_text("Auth session ticket handle: "+str(auth_ticket)+"\n\n")


func _on_BeginAuthSession_pressed() -> void:
	var RESPONSE: int = Steam.beginAuthSession(TICKET['buffer'], TICKET['size'], Global.STEAM_ID)
	# Get a verbose response
	var VERBOSE_RESPONSE: String
	match RESPONSE:
		0: VERBOSE_RESPONSE = "Ticket is valid for this game and this Steam ID."
		1: VERBOSE_RESPONSE = "The ticket is invalid."
		2: VERBOSE_RESPONSE = "A ticket has already been submitted for this Steam ID."
		3: VERBOSE_RESPONSE = "Ticket is from an incompatible interface version."
		4: VERBOSE_RESPONSE = "Ticket is not for this game."
		5: VERBOSE_RESPONSE = "Ticket has expired."
	$Frame/Main/Output.append_text("Auth verifcation response: "+str(VERBOSE_RESPONSE)+"\n\n")
	
	# If successful, add this client to the list
	if RESPONSE == 0:
		CLIENT_TICKETS.append({"id": Global.STEAM_ID, "ticket": TICKET['id']})
		# Allow the client to join the game


# Request an auth ticket from Steam
func _on_GetAuthTicket_pressed() -> void:
	TICKET = Steam.getAuthSessionTicket()
	$Frame/Main/Output.append_text("Auth Ticket: "+str(TICKET)+"\n\n")


# Send your auth ticket to the other client or server
func _send_Auth_Ticket() -> void:
	pass


# Callback from attempting to validate the auth ticket
func _validate_Auth_Ticket_Response(auth_id: int, response: int, owner_id: int) -> void:
	$Frame/Main/Output.append_text("Ticket Owner: "+str(auth_id)+"\n")
	# Make the response more verbose
	var VERBOSE_RESPONSE: String
	match response:
		0: VERBOSE_RESPONSE = "Steam has verified the user is online, the ticket is valid and ticket has not been reused."
		1: VERBOSE_RESPONSE = "The user in question is not connected to Steam."
		2: VERBOSE_RESPONSE = "The user doesn't have a license for this App ID or the ticket has expired."
		3: VERBOSE_RESPONSE = "The user is VAC banned for this game."
		4: VERBOSE_RESPONSE = "The user account has logged in elsewhere and the session containing the game instance has been disconnected."
		5: VERBOSE_RESPONSE = "VAC has been unable to perform anti-cheat checks on this user."
		6: VERBOSE_RESPONSE = "The ticket has been canceled by the issuer."
		7: VERBOSE_RESPONSE = "This ticket has already been used, it is not valid."
		8: VERBOSE_RESPONSE = "This ticket is not from a user instance currently connected to steam."
		9: VERBOSE_RESPONSE = "The user is banned for this game. The ban came via the web api and not VAC."
	$Frame/Main/Output.append_text("Auth response: "+str(VERBOSE_RESPONSE)+"\n")
	$Frame/Main/Output.append_text("Game owner ID: "+str(owner_id)+"\n\n")


#################################################
# ENDING AUTH SESSION FUNCTIONS
#################################################
# Cancel the auth ticket
func _on_CancelAuthTicket_pressed() -> void:
	Steam.cancelAuthTicket(TICKET['id'])
	$Frame/Main/Output.append_text("Canceling your auth ticket...\n\n")


# Ends the auth session with, well, you
func _on_EndAuthSession_pressed() -> void:
	# Loop through all client tickets and close them out
	for C in CLIENT_TICKETS:
		$Frame/Main/Output.append_text("Ending auth session with "+str(C['id'])+"\n\n")
		Steam.endAuthSession(C['id'])
		# Remove this client from the list
		CLIENT_TICKETS.erase(C)


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

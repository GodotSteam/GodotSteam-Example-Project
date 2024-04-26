extends Panel
#################################################
# AUTHENTICATION EXAMPLE
# https://godotsteam.com/tutorials/authentication/
#################################################

var auth_ticket: Dictionary		# Your auth auth_ticket
var client_auth_tickets: Array	# Array of clients auth_tickets

@onready var output: RichTextLabel = $Frame/Main/Output


func _ready() -> void:
	Helper.connect_signal(Steam.get_auth_session_ticket_response, 
			_on_get_auth_session_auth_ticket_response, 2)
		
	Helper.connect_signal(Steam.validate_auth_ticket_response,
			_on_validate_auth_ticket_response, 2)


#################################################
# STARTING AUTH SESSION FUNCTIONS
#################################################

func _on_begin_auth_session_pressed() -> void:
	if auth_ticket.is_empty():
		output.append_text("ERROR: auth_ticket is empty (Needs to be requested first!) \n\n")
		return
	
	var response: int = Steam.beginAuthSession(auth_ticket['buffer'], auth_ticket['size'], Global.steam_id)
	# Get a verbose response
	var verbose_response: String
	match response:
		0: verbose_response = "auth_ticket is valid for this game and this Steam ID."
		1: verbose_response = "The auth_ticket is invalid."
		2: verbose_response = "A auth_ticket has already been submitted for this Steam ID."
		3: verbose_response = "auth_ticket is from an incompatible interface version."
		4: verbose_response = "auth_ticket is not for this game."
		5: verbose_response = "auth_ticket has expired."
	output.append_text("Auth verifcation response: "+str(verbose_response)+"\n\n")
	
	# If successful, add this client to the list
	if response == 0:
		client_auth_tickets.append({"id": Global.steam_id, "auth_ticket": auth_ticket['id']})
		# Allow the client to join the game


# Request an auth auth_ticket from Steam
func _on_get_auth_ticket_pressed() -> void:
	auth_ticket = Steam.getAuthSessionTicket()
	output.append_text("Auth auth_ticket: "+str(auth_ticket)+"\n\n")


#################################################
# ENDING AUTH SESSION FUNCTIONS
#################################################

# Cancel the auth auth_ticket
func _on_cancel_auth_ticket_pressed() -> void:
	if auth_ticket.is_empty():
		output.append_text("ERROR: auth_ticket is empty (Needs to be requested first!) \n\n")
		return
	Steam.cancelAuthTicket(auth_ticket['id'])
	output.append_text("Canceling your auth_ticket "+str(auth_ticket['id'])+"...\n\n")
	# Note: This will trigger a validate_auth_ticket_response callback for any 
	# *other* server or client who called beginAuthSession using this ticket to 
	# let them know it is no longer valid.


# Ends the auth session with, ... well, you.
func _on_end_auth_session_pressed() -> void:
	# Loop through all client auth_tickets and close them out
	for ticket in client_auth_tickets:
		output.append_text("Ending auth session with "+str(ticket['id'])+"\n\n")
		Steam.endAuthSession(ticket['id'])
		# Remove this client from the list
		client_auth_tickets.erase(ticket)


#################################################
# CALLBACKS
#################################################

# Callback from getting the auth auth_ticket from Steam
func _on_get_auth_session_auth_ticket_response(auth_ticket_handle: int, result: int) -> void:
	output.append_text("Auth session result: "+str(result)+"\n")
	output.append_text("Auth session auth_ticket handle: "+str(auth_ticket_handle)+"\n\n")


# Callback from attempting to validate the auth auth_ticket
func _on_validate_auth_ticket_response(auth_id: int, response: int, owner_id: int) -> void:
	output.append_text("auth_ticket Owner: "+str(auth_id)+"\n")
	# Make the response more verbose
	var verbose_response: String
	match response:
		0: verbose_response = "Steam has verified the user is online, the auth_ticket is valid and auth_ticket has not been reused."
		1: verbose_response = "The user in question is not connected to Steam."
		2: verbose_response = "The user doesn't have a license for this App ID or the auth_ticket has expired."
		3: verbose_response = "The user is VAC banned for this game."
		4: verbose_response = "The user account has logged in elsewhere and the session containing the game instance has been disconnected."
		5: verbose_response = "VAC has been unable to perform anti-cheat checks on this user."
		6: verbose_response = "The auth_ticket has been canceled by the issuer."
		7: verbose_response = "This auth_ticket has already been used, it is not valid."
		8: verbose_response = "This auth_ticket is not from a user instance currently connected to steam."
		9: verbose_response = "The user is banned for this game. The ban came via the web api and not VAC."
	output.append_text("Auth response: "+str(verbose_response)+"\n")
	output.append_text("Game owner ID: "+str(owner_id)+"\n\n")

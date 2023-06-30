extends Node
#################################################
# NETWORKING GLOBAL SCRIPT
#################################################
var CONNECTION_HANDLE: int = 0
var CLIENT_CHANNEL: int = 1
var HOST_CHANNEL: int = 0
var VOICE_CHANNEL: int = 2


func _ready() -> void:
	pass



func _send_Message(message_contents) -> void:
	if CONNECTION_HANDLE > 0:
		var MESSAGE_REPONSE: Dictionary = Steam.sendMessageToConnection(CONNECTION_HANDLE, message_contents, 0)
		print("Send message: "+str(MESSAGE_REPONSE['result']+" / "+str(MESSAGE_REPONSE['message_number'])))
	else:
		print("No connection has been established")

extends Node
#################################################
# NETWORKING GLOBAL SCRIPT
################################################

var connection_handle: int = 0
var client_channel: int = 1
var host_channel: int = 0
var voice_channel: int = 2


func send_message(message_contents) -> void:
	if connection_handle > 0:
		var response: Dictionary = Steam.sendMessageToConnection(connection_handle, message_contents, 0)
		print("Send message: "+str(response['result']+" / "+str(response['message_number'])))
	else:
		print("No connection has been established")

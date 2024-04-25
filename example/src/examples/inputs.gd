extends Panel
#################################################
# INPUTS EXAMPLE
#################################################
# Steam's Inputs is somewhat unreliable sometimes
# Godot's input is a lot more reliable so we will be mixing the two in here for now


# Note: 6-9 are currently unused (as of 4/25/2024)
# See https://partner.steamgames.com/doc/api/ISteamInput#ESteamInputType
const STEAM_INPUT_TYPE_DICT : Dictionary = {
	0: "Catch-all for unrecognized devices",
	1:	"Valve's Steam Controller",
	2:	"Microsoft's XBox 360 Controller",
	3:	"Microsoft's XBox One Controller",
	4:	"Any generic 3rd-party XInput device",
	5:	"Sony's PlayStation 4 Controller",
	6:  "Unused",
	7:  "Unused",
	8:  "Unused",
	9:  "Unused",
	10:	"Nintendo's Switch Pro Controller",
	11:	"Steam Link App's Mobile Touch Controller",
	12:	"Sony's PlayStation 3 Controller or PS3/PS4 compatible fight stick",
}

var steam_controllers: Array
var godot_controllers: Array

@onready var output: RichTextLabel = $Frame/Main/Output


func _ready() -> void:
	# Godot Input Signals
	_connect_godot_input_signal("joy_connection_changed", _on_joy_connection_changed)
	
	# Steam Signals
	_connect_steam_signal("input_device_connected", _on_steam_input_device_connected)
	_connect_steam_signal("input_device_disconnected", _on_steam_input_device_disconnected)
	_connect_steam_signal("input_configuration_loaded", _on_steam_input_configuration_loaded)


func _on_steam_input_device_connected(input_handle : int):
	output.append_text("[Steam Input] Signal: Input device with handle " + str(input_handle) + " connected\n")


func _on_steam_input_device_disconnected(input_handle : int):
	output.append_text("[Steam Input] Signal: Input device with handle " + str(input_handle) + " disconnected\n")


func _on_steam_input_configuration_loaded(app_id: int, device_handle: int, config_data: Dictionary):
	output.append_text("[Steam Input] Signal: Input Configuration loaded: \n")
	output.append_text("- App ID: %s \n" % str(app_id))
	output.append_text("- Device Handle: %s \n" % str(device_handle))


# Get a list of all connected controllers
func _on_get_controllers_pressed() -> void:
	Steam.runFrame()
	
	# Get Steam's input list
	steam_controllers = Steam.getConnectedControllers()
	
	# Print the list to output
	output.append_text("[Steam Input] Found "+str(steam_controllers.size())+" connected controllers:\n")
	for controller in steam_controllers.size():
		output.append_text(str(steam_controllers[controller])+"\n")


# Get the input's type by handle
func _on_get_name_pressed() -> void:
	output.append_text("[Steam Inputs] Get input type by it's handle...\n\n")

	for controller in steam_controllers.size():
		var TYPE: int = Steam.getInputTypeForHandle(steam_controllers[controller])

		# Print it to the output
		var OUTPUT : String = "- %s has InputType of %s (%s)" % [
			str(steam_controllers[controller]), 
			str(TYPE), 
			STEAM_INPUT_TYPE_DICT[TYPE],
			]
		
		output.append_text(OUTPUT + "\n")


# Initialize the Inputs interface
func _on_init_pressed() -> void:
	# Get Godot's input list
	godot_controllers = Input.get_connected_joypads()
	
	# Print the list to output
	output.append_text("[Godot Input] Found "+str(godot_controllers.size())+" connected controllers:\n")
	for controller in godot_controllers:
		output.append_text("- " + str(Input.get_joy_name(godot_controllers[controller])) + "\n")
	
	#Spacing
	output.append_text(" \n")

	# Initialize Steam Inputs
	if Steam.inputInit():
		output.append_text("[Steam Input] Running!\n\n")
	else:
		output.append_text("[Steam Input] Not running... something went wrong.\n\n")

	# Start the frame run
	Steam.runFrame()


# Called whenever a joypad has been connected or disconnected.
func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		output.append_text(str(Input.get_joy_name(device_id))+"\n\n")


# Create a haptic pulse. 
# Note: Currently only the Steam Controller, Steam Deck, 
# and Nintendo Switch Pro Controller devices support haptic pulses. (4/25/2024)
func _on_haptic_pressed() -> void:
	output.append_text("[Steam Input] Sending haptic pulse to all applicable and connected controllers...\n\n")

	for controller in steam_controllers.size():
		Steam.triggerHapticPulse(steam_controllers[controller], 0, 500000)


# Create a repeated haptic pulse. 
# Note: Currently only the Steam Controller, Steam Deck, 
# and Nintendo Switch Pro Controller devices support haptic pulses. (4/25/2024)
func _on_haptic_repeated_pressed() -> void:
	output.append_text("[Steam Input] Sending repeated haptic pulse to all applicable and connected controllers...\n\n")

	for controller in steam_controllers.size():
		Steam.triggerRepeatedHapticPulse(steam_controllers[controller], 0, 50000, 500000, 10, 0)


# Shutdown the Inputs interface
func _on_shutdown_pressed() -> void:
	if Steam.inputShutdown(): # Note: Always returns true.
		output.append_text("[Steam Input] Shutdown successful.\n\n")


# Vibrate all connected input handles
# Note: This API call will be ignored for incompatible controller models. 
func _on_vibrate_pressed() -> void:
	output.append_text("[Steam Input] Vibrating all applicable and connected controllers...\n")

	for controller in steam_controllers.size():
		output.append_text("[Steam Input] Vibrating controller "+str(steam_controllers[controller])+" with speeds 5000\n")
		Steam.triggerVibration(steam_controllers[controller], 5000, 5000)


#################################################
# HELPER FUNCTIONS
#################################################
func _on_back_pressed() -> void:
	Loading.load_scene.emit("main")


func _connect_godot_input_signal(_signal: String, _function: Callable) -> void:
	var signal_connect : int = Input.connect(_signal, _function)
	if signal_connect > OK:
		printerr("[GODOT INPUT] Connecting "+str(_signal)+" to "+str(_function)+" failed: "+str(signal_connect))


# Connect a Steam signal and show the success code
func _connect_steam_signal(_signal: String, _function: Callable) -> void:
	var signal_connect = Steam.connect(_signal, _function)
	if signal_connect > OK:
		printerr("[STEAM] Connecting "+str(_signal)+" to "+str(_function)+" failed: "+str(signal_connect))

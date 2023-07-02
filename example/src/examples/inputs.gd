extends Panel
#################################################
# INPUTS EXAMPLE
#################################################
# Steam's Inputs is somewhat unreliable sometimes
# Godot's input is a lot more reliable so we will be mixing the two in here for now
var JOYSTICK_NUM
var CURRENT_JOYSTICK: int = -1
var AXIS_VALUE
var STEAM_CONTROLLERS: Array
var GODOT_CONTROLLERS: Array


func _ready() -> void:
	_connect_Godot_Signals("joy_connection_changed", "_on_Joy_Connection_Changed")


# Get a list of all connected controllers
func _on_GetControllers_pressed() -> void:
	Steam.runFrame()
	
	# Get Steam's input list
	STEAM_CONTROLLERS = Steam.getConnectedControllers()
	
	# Print the list to output
	$Frame/Main/Output.append_text("Steam found "+str(STEAM_CONTROLLERS.size())+" connected controllers:\n")
	for CONTROLLER in STEAM_CONTROLLERS.size():
		$Frame/Main/Output.append_text(str(STEAM_CONTROLLERS[CONTROLLER])+"\n")


# Get the input's type by handle
func _on_GetName_pressed() -> void:
	$Frame/Main/Output.append_text("[Steam Inputs] Get input type by it's handle...\n\n")

	for CONTROLLER in STEAM_CONTROLLERS.size():
		var TYPE: String = Steam.getInputTypeForHandle(STEAM_CONTROLLERS[CONTROLLER])

		# Print it to the output
		$Frame/Main/Output.append_text("For handle "+str(STEAM_CONTROLLERS[CONTROLLER])+": "+str(TYPE)+"\n")


# Initialize the Inputs interface
func _on_Init_pressed() -> void:
	# Get Godot's input list
	GODOT_CONTROLLERS = Input.get_connected_joypads()
	
	# Print the list to output
	$Frame/Main/Output.append_text("Godot found "+str(GODOT_CONTROLLERS.size())+" connected controllers:\n")
	for CONTROLLER in GODOT_CONTROLLERS:
		$Frame/Main/Output.append_text(str(Input.get_joy_name(GODOT_CONTROLLERS[CONTROLLER]))+"\n")

	# Initialize Steam Inputs
	if Steam.inputInit():
		$Frame/Main/Output.append_text("\nSteam Inputs is running!\n\n")
	else:
		$Frame/Main/Output.append_text("\nSteam Inputs is not running... something went wrong.\n\n")

	# Start the frame run
	Steam.runFrame()


# Called whenever a joypad has been connected or disconnected.
func _on_Joy_Connection_Changed(device_id: int, connected: bool) -> void:
	if connected:
		$Frame/Main/Output.append_text(str(Input.get_joy_name(device_id))+"\n\n")


# Create a haptic pulse
func _on_Haptic_pressed() -> void:
	$Frame/Main/Output.append_text("[Steam Inputs] Sending haptic pulse to all applicable and connected controllers...\n\n")

	for CONTROLLER in STEAM_CONTROLLERS.size():
		Steam.triggerHapticPulse(STEAM_CONTROLLERS[CONTROLLER], 0, 500000)


# Create a repeated haptic pulse
func _on_HapticRepeated_pressed() -> void:
	$Frame/Main/Output.append_text("[Steam Inputs] Sending repeated haptic pulse to all applicable and connected controllers...\n\n")

	for CONTROLLER in STEAM_CONTROLLERS.size():
		Steam.triggerRepeatedHapticPulse(STEAM_CONTROLLERS[CONTROLLER], 0, 50000, 500000, 10, 0)


# Shutdown the Inputs interface
func _on_Shutdown_pressed() -> void:
	if Steam.inputShutdown():
		$Frame/Main/Output.append_text("[Steam Inputs] Shutdown successfully.\n\n")
	else:
		$Frame/Main/Output.append_text("[Steam Inputs] Shutdown failed for some reason.\n\n")


# Vibrate all connected input handles
func _on_Vibrate_pressed() -> void:
	$Frame/Main/Output.append_text("[Steam Inputs] Vibrating all applicable and connected controllers...\n")

	for CONTROLLER in STEAM_CONTROLLERS.size():
		$Frame/Main/Output.append_text("[Steam Inputs] Vibrating controller "+str(STEAM_CONTROLLERS[CONTROLLER])+" with speeds 1000\n")
		Steam.triggerVibration(STEAM_CONTROLLERS[CONTROLLER], 5000, 5000)


#################################################
# HELPER FUNCTIONS
#################################################
func _on_Back_pressed() -> void:
	Loading._load_Scene("main")


func _connect_Godot_Signals(this_signal: String, this_function: String) -> void:
	var SIGNAL_CONNECT: int = Input.connect(this_signal, Callable(self, this_function))
	if SIGNAL_CONNECT > OK:
		print("[GODOT] Connecting "+str(this_signal)+" to "+str(this_function)+" failed: "+str(SIGNAL_CONNECT))


# Connect a Steam signal and show the success code
func _connect_Steam_Signals(this_signal: String, this_function: String) -> void:
	var SIGNAL_CONNECT: int = Steam.connect(this_signal, Callable(self, this_function))
	if SIGNAL_CONNECT > OK:
		print("[STEAM] Connecting "+str(this_signal)+" to "+str(this_function)+" failed: "+str(SIGNAL_CONNECT))

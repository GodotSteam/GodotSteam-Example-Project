extends Panel
#################################################
# INPUTS EXAMPLE
#################################################
# Steam's Inputs is somewhat unreliable sometimes
# Godot's input is a lot more reliable so we will be mixing the two in here for now
var current_controller: int = -1
var godot_controllers: Array
var haptic_strength: int = 100000
var steam_controllers: Array
var vibrate_strength: int = 100000


func _process(_delta: float) -> void:
	Steam.runFrame()


func _ready() -> void:
	Steam.enableDeviceCallbacks()

	connect_godot_signals("joy_connection_changed", "_on_joy_connection_changed")
	connect_steam_signals("input_device_connected", "_on_input_device_connected")
	connect_steam_signals("input_device_disconnected", "_on_input_device_disconnected")
	connect_steam_signals("input_configuration_loaded", "_on_input_configuration_loaded")
	connect_steam_signals("input_gamepad_slot_change", "_on_input_gamepad_slot_change")


#################################################
# START-UP / SHUTDOWN FUNCTIONS
#################################################
# Initialize the Inputs interface
func _on_init_pressed() -> void:
	# Get any controllers Godot can find first
	get_godot_controllers()

	# Initialize Steam Inputs
	if Steam.inputInit():
		get_node("%Output").add_new_text("\nSteam Inputs is running")
	else:
		get_node("%Output").add_new_text("\nSteam Inputs is not running... something went wrong")

	# Now ask Steam about connected controllers
	get_steam_controllers(true)


# Shutdown the Inputs interface
func _on_shutdown_pressed() -> void:
	if Steam.inputShutdown():
		get_node("%Output").add_new_text("\n[STEAM] Shutdown successfully")
	else:
		get_node("%Output").add_new_text("\n[STEAM] Shutdown failed for some reason")


#################################################
# CONTROLLER FUNCTIONS
#################################################
func get_godot_controllers() -> void:
	# Get Godot's input list
	godot_controllers = Input.get_connected_joypads()
	# Remove all previous controller names, just in case
	for controller_node in get_node("%GodotControllers").get_children():
			controller_node.hide()
			controller_node.queue_free()

	if godot_controllers.size() > 0:
		# Print the list to output
		get_node("%Output").add_new_text("\nGodot found %s connected controllers" % godot_controllers.size())
		for this_controller in godot_controllers:
			var this_controller_name: String = Input.get_joy_name(this_controller)
			get_node("%Output").add_new_text("- %s" % this_controller_name)
			get_node("%GodotControllers").add_child(create_controller_node(this_controller_name, this_controller))
	else:
		get_node("%Output").add_new_text("\nGodot found 0 connected controllers")
		get_node("%GodotControllers").add_child(create_controller_node("None", -1))


func get_steam_controllers(check_for_controllers: bool) -> void:
	if check_for_controllers:
		# Get Steam's input list
		steam_controllers = Steam.getConnectedControllers()

	# Remove all previous controller names, just in case
	for controller_node in get_node("%SteamControllers").get_children():
		controller_node.hide()
		controller_node.queue_free()

	if steam_controllers.size() > 0:
		# Print the list to output
		get_node("%Output").add_new_text("\nSteam found %s connected controllers:" % steam_controllers.size())
		for this_controller in steam_controllers:
			var this_controller_name: String = Steam.getInputTypeForHandle(this_controller)
			get_node("%Output").add_new_text("- "+str(this_controller_name))
			get_node("%SteamControllers").add_child(create_controller_node(this_controller_name, this_controller))
	else:
		get_node("%Output").add_new_text("\nSteam found 0 connected controllers\nYou may need to run this again")
		get_node("%SteamControllers").add_child(create_controller_node("None", -1))


# Get a list of all connected controllers
func _on_get_controllers_pressed() -> void:
	get_steam_controllers(true)


# Get the input's type by handle
func _on_get_name_pressed() -> void:
	get_node("%Output").add_new_text("\n[STEAM] Get input types by their handles...")
	get_steam_controllers(true)


#################################################
# UTILITY FUNCTIONS
#################################################
func _on_led_change_pressed() -> void:
	get_node("%Output").add_new_text("\nUpdating colors for Steam Controller and/or Steam Deck")
	for this_controller in steam_controllers:
		Steam.setLEDColor(this_controller, 105, 105, 105, Steam.INPUT_LED_FLAG_SET_COLOR)


# Show the Steam Input binding panel
func _on_show_binding_panel_pressed() -> void:
	if steam_controllers.size() > 0:
		if Steam.showBindingPanel(steam_controllers[current_controller]):
			get_node("%Output").add_new_text("\n[STEAM] Opening binding panel for controller: %s " % steam_controllers[current_controller])
		else:
			get_node("%Output").add_new_text("\nCould not open Steam Input binding panel for controller %s" % steam_controllers[current_controller])
	else:
		get_node("%Output").add_new_text("\nThere are no Steam Input controllers available for the binding panel")


#################################################
# VIBRATION AND HAPTIC FUNCTIONS
# These functions will run through all available
# and connected controllers
#################################################
func _on_extended_vibrate_pressed() -> void:
	get_node("%Output").add_new_text("\n[STEAM] Extended vibrating all applicable and connected controllers")

	for this_controller in steam_controllers:
		get_node("%Output").add_new_text("Vibrating controller %s with strength %s" % [this_controller, vibrate_strength])
		Steam.triggerVibrationExtended(this_controller, vibrate_strength, vibrate_strength, vibrate_strength, vibrate_strength)


func _on_haptic_pressed() -> void:
	get_node("%Output").add_new_text("\n[STEAM] Sending haptic pulse to all applicable and connected controllers")

	for this_controller in steam_controllers:
		Steam.triggerHapticPulse(this_controller, 0, haptic_strength)


func _on_haptic_repeated_pressed() -> void:
	get_node("%Output").add_new_text("\n[STEAM] Sending repeated haptic pulse to all applicable and connected controllers")

	for this_controller in steam_controllers:
		Steam.triggerRepeatedHapticPulse(this_controller, 0, haptic_strength, haptic_strength, 10, 0)


func _on_simple_haptic_pressed() -> void:
	get_node("%Output").add_new_text("\n[STEAM] Sending simple haptic pulse to all applicable and connected controllers")

	for this_controller in steam_controllers:
		Steam.triggerSimpleHapticEvent(this_controller, Steam.CONTROLLER_HAPTIC_LOCATION_BOTH, haptic_strength, "High", haptic_strength, "High")


func _on_vibrate_pressed() -> void:
	get_node("%Output").add_new_text("\n[STEAM] Vibrating all applicable and connected controllers")

	for this_controller in steam_controllers:
		get_node("%Output").add_new_text("Vibrating controller %s with strength %s" % [this_controller, vibrate_strength])
		Steam.triggerVibration(this_controller, vibrate_strength, vibrate_strength)


#################################################
# SIGNAL FUNCTIONS
#################################################
func _on_input_device_connected(input_handle: int) -> void:
	if not steam_controllers.has(input_handle):
		steam_controllers.append(input_handle)
	get_node("%Output").add_new_text("\n[STEAM] Controller %s connected" % input_handle)
	get_steam_controllers(false)


func _on_input_device_disconnected(input_handle: int) -> void:
	if steam_controllers.has(input_handle):
		steam_controllers.erase(input_handle)
	get_node("%Output").add_new_text("\n[STEAM] Controller %s disconnected" % input_handle)
	get_steam_controllers(false)


func _on_input_configuration_loaded(app_id: int, input_handle: int, config_data: Dictionary) -> void:
	get_node("%Output").add_new_text("\n[STEAM] Input configuration loaded for input %s" % input_handle)
	get_node("%Output").add_new_text("Configuration data for app : %s" % app_id)
	get_node("%Output").add_new_text("- Mapping creator: %s " % config_data['mapping_creator'])
	get_node("%Output").add_new_text("- Major revision: %s " % config_data['major_revision'])
	get_node("%Output").add_new_text("- Minor revision: %s " % config_data['minor_revision'])
	get_node("%Output").add_new_text("- Uses Steam Input API: %s " % config_data['uses_steam_input_api'])
	get_node("%Output").add_new_text("- Users Gamepad API: %s " % config_data['uses_gamepad_api'])


func _on_input_gamepad_slot_change(_app_id: int, input_handle: int, _input_type: int, old_gamepad_slot: int, new_gamepad_slot: int) -> void:
	get_node("%Output").add_new_text("\n[STEAM] Input %s gamepad slot changed from %s to %s" % [input_handle, old_gamepad_slot, new_gamepad_slot])


# From Godot, called whenever a joypad has been connected or disconnected.
func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	get_node("%Output").add_new_text("\n[GODOT] Device %s changed, connected: %s" % [Input.get_joy_name(device_id), connected])
	get_godot_controllers() 


#################################################
# HELPER FUNCTIONS
#################################################
func connect_godot_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Input.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])
	

func create_controller_node(this_text: String, this_controller_id: int) -> Object:
	var controller_node: Label = Label.new()
	var controller_theme: Theme = load("res://data/themes/label-theme.tres")

	if this_controller_id < 0:
		controller_node.set_text(str(this_text))
	else:
		controller_node.set_text("%s (%s)" % [this_text, this_controller_id])
	controller_node.set_theme(controller_theme)
	return controller_node


func _on_back_pressed() -> void:
	Loading.load_scene("main")

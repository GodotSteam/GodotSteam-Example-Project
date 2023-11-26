extends Panel
#################################################
# STEAM VOICE EXAMPLE
#
# Part is based on https://github.com/ikbencasdoei/godot-voip/
# Part is based on Valve's SpaceWar example, Voice.cpp / Voice.h files
# Additional ideas, details, and stuff from Punny and ynot01
#################################################
var current_sample_rate: int = 48000
var has_loopback: bool = false
var is_voice_toggled: bool = false
var local_playback: AudioStreamGeneratorPlayback = null
var local_voice_buffer: PoolByteArray = PoolByteArray()
var network_playback: AudioStreamGeneratorPlayback = null
var network_voice_buffer: PoolByteArray = PoolByteArray()
var packet_read_limit: int = 5
var use_optimal_sample_rate: bool = false


func _ready() -> void:
	for this_notification in $Frame/Main/Notifications.get_children():
		if this_notification.name != "Off":
			this_notification.hide()


func _process(_delta: float) -> void:
	# Essentially checking for the local voice data then sending it to the networking
	# Plays locally if loopback is enabled
	check_for_voice()


#################################################
# BUTTON HANDLING
#################################################
# So you can hear yourself, duh
func _on_loopback_pressed() -> void:
	has_loopback = !has_loopback
	print("Loopback enabled: %s" % has_loopback)
	$Frame/Main/Notifications/Loopback.set_visible(has_loopback)


func _on_optimal_pressed() -> void:
	use_optimal_sample_rate = !use_optimal_sample_rate
	$Frame/Main/Notifications/Optimal.set_visible(use_optimal_sample_rate)


func _on_toggle_voice_pressed() -> void:
	is_voice_toggled = !is_voice_toggled
	print("Toggling voice chat: %s" % is_voice_toggled)
	change_voice_status()


func _on_to_talk_button_down() -> void:
	print("Starting voice chat")
	is_voice_toggled = true
	change_voice_status()


func _on_to_talk_button_up() -> void:
	print("Stopping voice chat")
	is_voice_toggled = false
	change_voice_status()


#################################################
# VOICE FUNCTIONS
#################################################
func change_voice_status() -> void:
	$Frame/Main/Notifications/On.set_visible(is_voice_toggled)
	$Frame/Main/Notifications/Off.set_visible(!is_voice_toggled)
	# If talking, it suppresses all other voice comms from Steam UI
	Steam.setInGameVoiceSpeaking(Global.steam_id, is_voice_toggled)

	if is_voice_toggled:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()


func check_for_voice() -> void:
	var available_voice: Dictionary = Steam.getAvailableVoice()
	if available_voice['result'] == Steam.VOICE_RESULT_OK and available_voice['buffer'] > 0:
		print("Voice message found")
		# Valve's getVoice uses 1024 but GodotSteam's is set at 8192?
		# Our sizes might be way off; internal GodotSteam notes that Valve suggests 8kb
		# However, this is not mentioned in the header nor the SpaceWar example but -is- in Valve's docs which are usually wrong
		var voice_data: Dictionary = Steam.getVoice()
		if voice_data['result'] == Steam.VOICE_RESULT_OK and voice_data['written']:
			print("Voice message has data: %s / %s" % [voice_data['result'], voice_data['written']])
			Networking.send_message(voice_data['buffer'])
			# If loopback is enable, play it back at this point
			if has_loopback:
				print("Loopback on")
				process_voice_data(voice_data, "local")


func get_sample_rate() -> void:
	var optimal_sample_rate: int = Steam.getVoiceOptimalSampleRate()
	# SpaceWar uses 11000 for sample rate?!
	# If are using Steam's "optimal" rate, set it; otherwise we default to 48000
	if use_optimal_sample_rate:
		current_sample_rate = optimal_sample_rate
	else:
		current_sample_rate = 48000
	print("Current sample rate: %s" % current_sample_rate)


# A network voice packet exists, process it
func play_network_voice(voice_data: Dictionary) -> void:
	process_voice_data(voice_data, "remote")


# Works but has stuttering
func process_voice_data(voice_data: Dictionary, voice_source: String) -> void:
	get_sample_rate()

	var decompressed_voice: Dictionary = Steam.decompressVoice(voice_data['buffer'], voice_data['written'], current_sample_rate)
	if decompressed_voice['result'] == Steam.VOICE_RESULT_OK and decompressed_voice['size'] > 0:
		print("Decompressed voice: %s" % decompressed_voice['size'])
		if voice_source == "local":
			local_voice_buffer = decompressed_voice['uncompressed']
			local_voice_buffer.resize(decompressed_voice['size'])
			var local_audio: AudioStreamSample = AudioStreamSample.new()
			local_audio.mix_rate = current_sample_rate
			local_audio.data = local_voice_buffer
			local_audio.format = AudioStreamSample.FORMAT_16_BITS
			$Frame/Main/Players/Local.stream = local_audio
			$Frame/Main/Players/Local.play()


#################################################
# HELPER FUNCTIONS
#################################################
func _on_back_pressed() -> void:
	Loading.load_scene("main")

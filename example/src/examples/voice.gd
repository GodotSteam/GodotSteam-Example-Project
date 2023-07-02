extends Panel
#################################################
# STEAM VOICE EXAMPLE
#
# Part is based on https://github.com/ikbencasdoei/godot-voip/
# Part is based on Valve's SpaceWar example, Voice.cpp / Voice.h files
# Additional ideas, details, and stuff from Punny and ynot01
#################################################
var CURRENT_SAMPLE_RATE: int = 48000
var HAS_LOOPBACK: bool = false
var IS_VOICE_TOGGLED: bool = false
var LOCAL_PLAYBACK: AudioStreamGeneratorPlayback = null
var LOCAL_VOICE_BUFFER: PackedByteArray = PackedByteArray()
var NETWORK_PLAYBACK: AudioStreamGeneratorPlayback = null
var NETWORK_VOICE_BUFFER: PackedByteArray = PackedByteArray()
var PACKET_READ_LIMIT: int = 5
var USE_OPTIMAL_SAMPLE_RATE: bool = false


func _ready() -> void:
	for NOTIFICATION in $Frame/Main/Notifications.get_children():
		if NOTIFICATION.name != "Off":
			NOTIFICATION.hide()


func _process(_delta: float) -> void:
	# Essentially checking for the local voice data then sending it to the networking
	# Plays locally if loopback is enabled
	_check_For_Voice()


#################################################
# BUTTON HANDLING
#################################################
# So you can hear yourself, duh
func _on_Loopback_pressed() -> void:
	HAS_LOOPBACK = !HAS_LOOPBACK
	print("Loopback enabled: "+str(HAS_LOOPBACK))
	$Frame/Main/Notifications/Loopback.set_visible(HAS_LOOPBACK)


func _on_Optimal_pressed() -> void:
	USE_OPTIMAL_SAMPLE_RATE = !USE_OPTIMAL_SAMPLE_RATE
	$Frame/Main/Notifications/Optimal.set_visible(USE_OPTIMAL_SAMPLE_RATE)


func _on_ToggleVoice_pressed() -> void:
	IS_VOICE_TOGGLED = !IS_VOICE_TOGGLED
	print("Toggling voice chat: "+str(IS_VOICE_TOGGLED))
	_change_Voice_Status()


func _on_ToTalk_button_down() -> void:
	print("Starting voice chat")
	IS_VOICE_TOGGLED = true
	_change_Voice_Status()


func _on_ToTalk_button_up() -> void:
	print("Stopping voice chat")
	IS_VOICE_TOGGLED = false
	_change_Voice_Status()


#################################################
# VOICE FUNCTIONS
#################################################
func _change_Voice_Status() -> void:
	$Frame/Main/Notifications/On.set_visible(IS_VOICE_TOGGLED)
	$Frame/Main/Notifications/Off.set_visible(!IS_VOICE_TOGGLED)
	# If talking, it suppresses all other voice comms from Steam UI
	Steam.setInGameVoiceSpeaking(Global.STEAM_ID, IS_VOICE_TOGGLED)

	if IS_VOICE_TOGGLED:
		Steam.startVoiceRecording()
	else:
		Steam.stopVoiceRecording()


func _check_For_Voice() -> void:
	var AVAILABLE_VOICE: Dictionary = Steam.getAvailableVoice()
	if AVAILABLE_VOICE['result'] == Steam.VOICE_RESULT_OK and AVAILABLE_VOICE['buffer'] > 0:
		print("Voice message found")
		# Valve's getVoice uses 1024 but GodotSteam's is set at 8192?
		# Our sizes might be way off; internal GodotSteam notes that Valve suggests 8kb
		# However, this is not mentioned in the header nor the SpaceWar example but -is- in Valve's docs which are usually wrong
		var VOICE_DATA: Dictionary = Steam.getVoice()
		if VOICE_DATA['result'] == Steam.VOICE_RESULT_OK and VOICE_DATA['written']:
			print("Voice message has data: "+str(VOICE_DATA['result'])+" / "+str(VOICE_DATA['written']))
			Networking._send_Message(VOICE_DATA['buffer'])
			# If loopback is enable, play it back at this point
			if HAS_LOOPBACK:
				print("Loopback on")
				_process_Voice_Data(VOICE_DATA, "local")


func _get_Sample_Rate() -> void:
	var OPTIMAL_SAMPLE_RATE: int = Steam.getVoiceOptimalSampleRate()
	# SpaceWar uses 11000 for sample rate?!
	# If are using Steam's "optimal" rate, set it; otherwise we default to 48000
	if USE_OPTIMAL_SAMPLE_RATE:
		CURRENT_SAMPLE_RATE = OPTIMAL_SAMPLE_RATE
	else:
		CURRENT_SAMPLE_RATE = 48000
	print("Current sample rate: "+str(CURRENT_SAMPLE_RATE))


# A network voice packet exists, process it
func _play_Network_Voice(voice_data: Dictionary) -> void:
	_process_Voice_Data(voice_data, "remote")


# Works but has stuttering
func _process_Voice_Data(voice_data: Dictionary, voice_source: String) -> void:
	_get_Sample_Rate()

	var DECOMPRESSED_VOICE: Dictionary = Steam.decompressVoice(voice_data['buffer'], voice_data['written'], CURRENT_SAMPLE_RATE)
	if DECOMPRESSED_VOICE['result'] == Steam.VOICE_RESULT_OK and DECOMPRESSED_VOICE['size'] > 0:
		print("Decompressed voice: "+str(DECOMPRESSED_VOICE['size']))
		if voice_source == "local":
			LOCAL_VOICE_BUFFER = DECOMPRESSED_VOICE['uncompressed']
			LOCAL_VOICE_BUFFER.resize(DECOMPRESSED_VOICE['size'])
			var LOCAL_AUDIO: AudioStreamWAV = AudioStreamWAV.new()
			LOCAL_AUDIO.mix_rate = CURRENT_SAMPLE_RATE
			LOCAL_AUDIO.data = LOCAL_VOICE_BUFFER
			LOCAL_AUDIO.format = AudioStreamWAV.FORMAT_16_BITS
			$Frame/Main/Players/Local.stream = LOCAL_AUDIO
			$Frame/Main/Players/Local.play()


#################################################
# HELPER FUNCTIONS
#################################################
func _on_Back_pressed() -> void:
	Loading._load_Scene("main")

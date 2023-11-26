extends Panel
#################################################
# MUSIC EXAMPLE
# This covers functions from the Music class
#################################################


func _ready() -> void:
	# Get some basic data from Steam Music
	is_music_enabled()
	is_music_playing()
	_on_music_get_volume()


#################################################
# MUSIC FUNCTIONS
# These functions are contained in the Music class
# They are pretty basic functions for interacting with
# the Steam client's music interface
#################################################
# Just for checking if music is enabled, obviously
# We could disable all these other functions if it returned false
func is_music_enabled() -> void:
	var is_enabled: bool = Steam.musicIsEnabled()
	get_node("%Output").add_new_text("Steam Music enabled: %s" % is_enabled)


# Just for checking if music is playing, obviously
# We could disable certain functions if it returned false
func is_music_playing() -> void:
	var is_playing: bool = Steam.musicIsPlaying()
	get_node("%Output").add_new_text("Steam Music playing: %s" % is_playing)


func _on_get_playback_status() -> void:
	var this_status: int = Steam.getPlaybackStatus()
	get_node("%Output").add_new_text("Playback status: %s" % make_playback_readable(this_status))


# Get the volume level from the Steam client
# We mostly just use this to sync our in-app volume slider
func _on_music_get_volume() -> void:
	var cur_volume: float = Steam.musicGetVolume()
	$Frame/Main/Interface/Volume.set_value(cur_volume)
	get_node("%Output").add_new_text("Current Steam client volume: %s" % cur_volume)


func _on_music_pause() -> void:
	Steam.musicPause()


func _on_music_play() -> void:
	Steam.musicPlay()


func _on_music_play_next() -> void:
	Steam.musicPlayNext()


func _on_music_play_prev() -> void:
	Steam.musicPlayPrev()


func _on_music_set_volume(volume: float) -> void:
	get_node("%Output").add_new_text("Setting Steam client volume to: "+str(volume))
	Steam.musicSetVolume(volume)


func _on_volume_drag_ended(is_value_changed: bool) -> void:
	if is_value_changed:
		var new_volume: float = $Frame/Main/Interface/Volume.get_value()
		get_node("%Output").add_new_text("Changed volume to: %s" % new_volume)
		_on_music_set_volume(new_volume)


#################################################
# HELPER FUNCTIONS
#################################################
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


# Change the playback status enum to something human readable
func make_playback_readable(this_status: int) -> String:
	var verbal_status: String = "undefined"
	match this_status:
		Steam.AUDIO_PLAYBACK_IDLE: verbal_status = "idle"
		Steam.AUDIO_PLAYBACK_PAUSED: verbal_status = "paused"
		Steam.AUDIO_PLAYBACK_PLAYING: verbal_status = "playing"
		_: verbal_status = "undefined"
	return verbal_status


func _on_back_pressed() -> void:
	Loading.load_scene("main")

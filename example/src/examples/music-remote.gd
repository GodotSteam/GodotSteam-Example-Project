extends Panel
#################################################
# MUSIC / MUSIC REMOTE EXAMPLE
# This covers functions from the Music and Music Remote class.
#################################################
var remote_display_name: String = ""
var remote_music_name: String = ""


func _ready() -> void:
	# Let's connect a LOT of signals
	connect_steam_signals("music_player_remote_to_front", "_on_remote_to_front")
	connect_steam_signals("music_player_remote_will_activate", "_on_remote_will_activate")
	connect_steam_signals("music_player_remote_will_deactivate", "_on_remote_will_deactivate")
	connect_steam_signals("music_player_selects_playlist_entry", "_on_selects_playlist_entry")
	connect_steam_signals("music_player_selects_queue_entry", "_on_selects_queue_entry")
	connect_steam_signals("music_player_wants_looped", "_on_wants_looped")
	connect_steam_signals("music_player_wants_pause", "_on_wants_pause")
	connect_steam_signals("music_player_wants_playing_repeat_status", "_on_wants_playing_repeat_status")
	connect_steam_signals("music_player_wants_play_next", "_on_wants_play_next")
	connect_steam_signals("music_player_wants_play_previous", "_on_wants_play_previous")
	connect_steam_signals("music_player_wants_play", "_on_wants_play")
	connect_steam_signals("music_player_wants_shuffled", "_on_wants_shuffled")
	connect_steam_signals("music_player_wants_volume", "_on_wants_volume")
	connect_steam_signals("music_player_will_quit", "_on_will_quit")
	# Get some basic data from Steam Music
	is_music_enabled()
	is_music_playing()
	_on_music_get_volume()


#################################################
# CALLBACK FUNCTIONS
#################################################
func _on_remote_to_front() -> void:
	get_node("%Output").add_new_text("Remote to front")


func _on_remote_will_activate() -> void:
	get_node("%Output").add_new_text("Remote will activate")


func _on_remote_will_deactivate() -> void:
	get_node("%Output").add_new_text("Remote will deactivate")


func _on_selects_playlist_entry(this_entry: int) -> void:
	get_node("%Output").add_new_text("Remote selected playlist entry: %s" % this_entry)


func _on_selects_queue_entry(this_entry: int) -> void:
	get_node("%Output").add_new_text("Remote selected queue entry: %s" % this_entry)


func _on_wants_looped(wants_looped: bool) -> void:
	get_node("%Output").add_new_text("Remote wants looped: %s" % wants_looped)


func _on_wants_pause() -> void:
	get_node("%Output").add_new_text("Remote wants pause")


func _on_wants_playing_repeat_status(this_status: int) -> void:
	get_node("%Output").add_new_text("Remote wants repeat status: %s" % this_status)


func _on_wants_play_next() -> void:
	get_node("%Output").add_new_text("Remote wants play next")


func _on_wants_play_previous() -> void:
	get_node("%Output").add_new_text("Remote wants play previous")


func _on_wants_play() -> void:
	get_node("%Output").add_new_text("Remote wants play")


func _on_wants_shuffled(wants_shuffle: bool) -> void:
	get_node("%Output").add_new_text("Remote wants shuffle: %s" % wants_shuffle)


func _on_wants_volume(new_volume: float) -> void:
	get_node("%Output").add_new_text("Remote wants new volume: %s" % new_volume)


func _on_will_quit() -> void:
	get_node("%Output").add_new_text("Remote will quit soon")


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
	get_node("%Output").add_new_text("Setting Steam client volume to: %s" % volume)
	Steam.musicSetVolume(volume)


func _on_volume_drag_ended(is_value_changed: bool) -> void:
	if is_value_changed:
		var new_volume: float = $Frame/Main/Interface/Volume.get_value()
		get_node("%Output").add_new_text("Changed volume to: %s" % new_volume)
		_on_music_set_volume(new_volume)


#################################################
# SERVICE FUNCTIONS
# Related to, presumably, starting and ending a Music Remote session
#################################################
func _on_deregister_steam_music_remote() -> void:
	var is_deregister: bool = Steam.deregisterSteamMusicRemote()
	get_node("%Output").add_new_text("Steam Music Remote session deregistered: %s" % is_deregister)
	if is_deregister:
		$Frame/Main/Register/Deregister.set_disabled(true)
		$Frame/Main/Register/RegisterMusicRemote.set_disabled(false)
		$Frame/Main/Register/RemoteName.set_editable(true)


func _on_register_steam_music_remote() -> void:
	remote_music_name = $Frame/Main/Register/RemoteName.get_text()
	var remote_registered: bool = Steam.registerSteamMusicRemote(remote_music_name)
	if remote_registered:
		$Frame/Main/Register/Deregister.set_disabled(false)
		$Frame/Main/Register/RegisterMusicRemote.set_disabled(true)
		$Frame/Main/Register/RemoteName.clear()
		$Frame/Main/Register/RemoteName.set_editable(false)
	get_node("%Output").add_new_text("Steam Music Remote registered: %s" % remote_registered)


func _on_register_steam_music_remote_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		$Frame/Main/Register/RegisterMusicRemote.set_disabled(false)
	else:
		$Frame/Main/Register/RegisterMusicRemote.set_disabled(true)


func _on_register_steam_music_remote_text_entered(new_text: String) -> void:
	remote_music_name = new_text
	_on_register_steam_music_remote()


func _on_set_display_name_pressed() -> void:
	remote_display_name = $Frame/Main/Display/DisplayName.get_text()
	var is_display_name_set: bool = Steam.setDisplayName(remote_display_name)
	if is_display_name_set:
		$Frame/Main/Display/DisplayName.clear()
	get_node("%Output").add_new_text("Steam Music Remote display name set to: %s / %s" % [remote_display_name, is_display_name_set])


func _on_set_display_name_text_changed(new_text: String) -> void:
	if new_text.length() > 0:
		$Frame/Main/Display/SetDisplayName.set_disabled(false)
	else:
		$Frame/Main/Display/SetDisplayName.set_disabled(true)


func _on_set_display_name_text_entered(new_text: String) -> void:
	remote_display_name = new_text
	_on_set_display_name_pressed()


#func activationSuccess(bool activate);


func _on_is_current_music_remote() -> void:
	var is_music_remote: bool = Steam.isCurrentMusicRemote()
	get_node("%Output").add_new_text("Is the currently playing music remote: %s" % is_music_remote)


 #bool setPNGIcon64x64(PoolByteArray icon);


#################################################
# INTERFACE FUNCTIONS
#################################################
func _on_enable_looped(enable_loop: bool) -> void:
	toggle_button_text(enable_loop, "Looped")
	if not Steam.enableLooped(enable_loop):
		get_node("%Output").add_new_text("Failed to enable looped in client")


func _on_enable_playlists(enable_playlists: bool) -> void:
	toggle_button_text(enable_playlists, "Playlists")
	if not Steam.enablePlaylists(enable_playlists):
		get_node("%Output").add_new_text("Failed to enable playlists in client")


func _on_enable_play_next(enable_next: bool) -> void:
	toggle_button_text(enable_next, "Next")
	if not Steam.enablePlayNext(enable_next):
		get_node("%Output").add_new_text("Failed to enable play next in client")


func _on_enable_play_previous(enable_previous: bool) -> void:
	toggle_button_text(enable_previous, "Previous")
	if not Steam.enablePlayPrevious(enable_previous):
		get_node("%Output").add_new_text("Failed to enable play previous in client")


func _on_enable_queue(enable_queue: bool) -> void:
	toggle_button_text(enable_queue, "Queue")
	if not Steam.enableQueue(enable_queue):
		get_node("%Output").add_new_text("Failed to enable queue in client")


func _on_enable_shuffled(enable_shuffle: bool) -> void:
	toggle_button_text(enable_shuffle, "Shuffled")
	if not Steam.enableShuffled(enable_shuffle):
		get_node("%Output").add_new_text("Failed to enable shuffle in client")


#################################################
# STATUS FUNCTIONS
#################################################
func _set_music_looped(set_looped: bool) -> void:
	if Steam.updateLooped(set_looped):
		get_node("%Output").add_new_text("Music set to looped")
	else:
		get_node("%Output").add_new_text("Music set to not looped")


#		bool updatePlaybackStatus(AudioPlaybackStatus status);


func _set_music_shuffled(set_shuffled: bool) -> void:
	if Steam.updateShuffled(set_shuffled):
		get_node("%Output").add_new_text("Music set to shuffled")
	else:
		get_node("%Output").add_new_text("Music set to not shuffled")


#		bool updateVolume(float volume);


#################################################
# CURRENT ENTRY FUNCTIONS
#################################################
#		bool currentEntryDidChange();
#		bool currentEntryIsAvailable(bool available);
#		bool currentEntryWillChange();
#		bool updateCurrentEntryCoverArt(PoolByteArray art);
#		bool updateCurrentEntryElapsedSeconds(int seconds);
#		bool updateCurrentEntryText(const String& text);


#################################################
# QUEUE FUNCTIONS
#################################################
#bool queueDidChange();
#bool queueWillChange();
#bool resetQueueEntries();
#bool setQueueEntry(int id, int position, const String& entry_text);
#bool setCurrentQueueEntry(int id);


#################################################
# PLAYLIST FUNCTIONS
#################################################
#		bool playlistDidChange();
#		bool playlistWillChange();
#		bool setCurrentPlaylistEntry(int id);
#		bool resetPlaylistEntries();
#		bool setPlaylistEntry(int id, int position, const String& entry_text);


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


func toggle_button_text(is_toggled: bool, this_button: String) -> void:
	if is_toggled:
		get_node("Frame/Sidebar/Options/List/"+this_button).set_text("Disable "+this_button)
	else:
		get_node("Frame/Sidebar/Options/List/"+this_button).set_text("Enable "+this_button)

extends Control
#################################################
# Stored at the class level to enable comparisons when helper functions are called
var avatar: Image
var steam_id: int = 0

signal kick_player


func _ready() -> void:
	connect_steam_signals("avatar_loaded", "_on_loaded_avatar")


# Kick this player
# Should only work if you are the host or vote-kicking is enabled
func _on_kick_pressed():
	emit_signal("kick_player", steam_id)


# View this player's profile on Steam
func _on_view_pressed() -> void:
	Steam.activateGameOverlayToUser("steamid", steam_id)


# Set this player up
func set_new_member(this_steam_id: int, steam_name: String) -> void:
	# Set the ID and username
	steam_id = this_steam_id
	$Member/Stuff/Username.set_text(steam_name)
	# Get the avatar and show it
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, this_steam_id)


#################################################
# HELPER FUNCTIONS
#################################################
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])


func _on_loaded_avatar(this_id: int, this_size: int, this_buffer: PoolByteArray) -> void:
	# Check we're only triggering a load for the right player, and check the data has actually changed
	if this_id == steam_id and (not avatar or not this_buffer == avatar.get_data()):
		print("Loading avatar for user: %s" % this_id)
		# Create the image and texture for loading
		# Apply the image data from Steam then set the texture to our sprite
		avatar = Image.new()
		var avatar_texture: ImageTexture = ImageTexture.new()

		avatar.create_from_data(this_size, this_size, false, Image.FORMAT_RGBA8, this_buffer)
		avatar_texture.create_from_image(avatar)

		$Member/Avatar.set_texture(avatar_texture)

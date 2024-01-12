extends Panel
#################################################
# avatar_image EXAMPLE
#################################################


func _ready() -> void:
	connect_steam_signals("avatar_loaded", "_on_loaded_avatar")


func _on_loaded_avatar(id: int, size: int, buffer: PoolByteArray) -> void:
	print("Avatar for user: "+str(id)+", size: "+str(size))
	# Create the image and texture for loading
	# Apply the avatar data from Steam then set this to our sprite
	var avatar_image: Image = Image.new()
	var avatar_texture: ImageTexture = ImageTexture.new()

	avatar_image.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	avatar_texture.create_from_image(avatar_image)

	if size == 32:
		$Frame/Main/Images/Small/Avatar.set_texture(avatar_texture)
	elif size == 64:
		$Frame/Main/Images/Medium/Avatar.set_texture(avatar_texture)
	else:
		$Frame/Main/Images/Large/Label.set_text("Large Avatar - 128 x 128 pixels (Retrieved as "+str(size)+" pixels)")
		$Frame/Main/Images/Large/Avatar.set_texture(avatar_texture)


# Load avatars buttons, pass the size you want and the player's Steam ID
func _on_request_avatar_pressed(this_size: String) -> void:
	match this_size:
		"large":
			Steam.getPlayerAvatar(Steam.AVATAR_LARGE, Global.steam_id)
		"medium":
			Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, Global.steam_id)
		"small":
			Steam.getPlayerAvatar(Steam.AVATAR_SMALL, Global.steam_id)


#################################################
# HELPER FUNCTIONS
#################################################
# Connect a Steam signal and show the success code
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var SIGNAL_CONNECT: int = Steam.connect(this_signal, self, this_function)
	if SIGNAL_CONNECT > OK:
		print("Connecting "+str(this_signal)+" to "+str(this_function)+" failed: "+str(SIGNAL_CONNECT))


func _on_back_pressed() -> void:
	Loading.load_scene("main")

extends Panel
#################################################
# AVATAR EXAMPLE
#################################################
func _ready() -> void:
	_connect_Steam_Signals("avatar_loaded", "_loaded_Avatar")


# Avatar is ready for display
func _loaded_Avatar(id: int, size: int, buffer: PoolByteArray) -> void:
	print("Avatar for user: "+str(id)+", size: "+str(size))

	# Create the image and texture for loading
	var AVATAR: Image = Image.new()
	var AVATAR_TEXTURE: ImageTexture = ImageTexture.new()
	AVATAR.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)

	# Apply it to the texture
	AVATAR_TEXTURE.create_from_image(AVATAR)

	# Display it
	if size == 32:
		$Frame/Main/Images/Small/Avatar.set_texture(AVATAR_TEXTURE)
	elif size == 64:
		$Frame/Main/Images/Medium/Avatar.set_texture(AVATAR_TEXTURE)
	else:
		$Frame/Main/Images/Large/Label.set_text("Large Avatar - 128 x 128 pixels (Retrieved as "+str(size)+" pixels)")
		$Frame/Main/Images/Large/Avatar.set_texture(AVATAR_TEXTURE)


# Load avatars buttons, pass the size you want and the player's Steam ID
func _on_Large_pressed() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_LARGE, Global.STEAM_ID)


func _on_Medium_pressed() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, Global.STEAM_ID)


func _on_Small_pressed() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_SMALL, Global.STEAM_ID)


#################################################
# HELPER FUNCTIONS
#################################################
func _on_Back_pressed() -> void:
	Loading._load_Scene("main")


# Connect a Steam signal and show the success code
func _connect_Steam_Signals(this_signal: String, this_function: String) -> void:
	var SIGNAL_CONNECT: int = Steam.connect(this_signal, self, this_function)
	if SIGNAL_CONNECT > OK:
		print("[STEAM] Connecting "+str(this_signal)+" to "+str(this_function)+" failed: "+str(SIGNAL_CONNECT))

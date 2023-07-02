extends Panel
#################################################
# AVATAR EXAMPLE
#################################################
func _ready() -> void:
	_connect_Steam_Signals("avatar_loaded", "_loaded_Avatar")


# Avatar is ready for display
func _loaded_Avatar(id: int, avatar_size: int, buffer: PackedByteArray) -> void:
	print("Avatar for user: "+str(id)+", size: "+str(avatar_size))

	# Create the image and texture for loading
	var AVATAR: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, buffer)

	# Display it
	if avatar_size == 32:
		$Frame/Main/Images/Small/Avatar.set_texture(ImageTexture.create_from_image(AVATAR))
	elif avatar_size == 64:
		$Frame/Main/Images/Medium/Avatar.set_texture(ImageTexture.create_from_image(AVATAR))
	else:
		$Frame/Main/Images/Large/Label.set_text("Large Avatar - 128 x 128 pixels (Retrieved as "+str(avatar_size)+" pixels)")
		$Frame/Main/Images/Large/Avatar.set_texture(ImageTexture.create_from_image(AVATAR))


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
	var SIGNAL_CONNECT: int = Steam.connect(this_signal, Callable(self, this_function))
	if SIGNAL_CONNECT > OK:
		print("[STEAM] Connecting "+str(this_signal)+" to "+str(this_function)+" failed: "+str(SIGNAL_CONNECT))

extends Panel
#################################################
# AVATAR EXAMPLE
# https://godotsteam.com/tutorials/avatars/
#################################################


@onready var avatar_small: TextureRect = $"Frame/Main/Images/Small/Avatar Small"
@onready var avatar_medium: TextureRect = $"Frame/Main/Images/Medium/Avatar Medium"
@onready var avatar_large: TextureRect = $"Frame/Main/Images/Large/Avatar Large"
@onready var avatar_large_label: Label = $"Frame/Main/Images/Large/Label Large"

func _ready() -> void:
	Helper.connect_signal(Steam.avatar_loaded, _on_avatar_loaded, 2)


#################################################
# AVATAR LOAD FUNCTIONS
#################################################

# Load avatars buttons
func _on_large_pressed() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_LARGE, Global.steam_id)


func _on_medium_pressed() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, Global.steam_id)


func _on_small_pressed() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_SMALL, Global.steam_id)


#################################################
# CALLBACKS
#################################################

# Avatar is ready for display
func _on_avatar_loaded(id: int, avatar_size: int, buffer: PackedByteArray) -> void:
	print("Avatar for user: "+str(id)+", size: "+str(avatar_size))

	# Create the image and texture for loading
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, 
			false, Image.FORMAT_RGBA8, buffer)
		
	var avatar_texture : ImageTexture = ImageTexture.create_from_image(avatar_image)	
			
	# Display it
	if avatar_size == 32:
		avatar_small.texture = avatar_texture
	elif avatar_size == 64:
		avatar_medium.set_texture(avatar_texture)
	else:
		# Resizing Image to 128x128
		if avatar_size > 128:
			avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		avatar_large_label.set_text("Large Avatar - 128 x 128 pixels (Retrieved as "+str(avatar_size)+" pixels)")
		
		avatar_large.set_texture(avatar_texture)

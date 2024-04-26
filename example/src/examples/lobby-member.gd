extends Control
class_name LobbyMember

signal kick_player(player_steam_id : int)

var steam_id: int = 0
var steam_name: String = "[empty]"

# Stored at the class level to enable comparisons when helper functions are called
var user_avatar: Image

@export var username_label: Label
@export var avatar_rect: TextureRect
@export var button_kick: Button

func _ready():
	Helper.connect_signal(Steam.avatar_loaded, on_avatar_loaded)


# Set this player up
func set_member(_steam_id: int, _steam_name: String) -> void:
	# Set the ID and username
	steam_id = _steam_id
	steam_name = _steam_name
	
	username_label.set_text(steam_name)
	# Get the avatar and show it
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, steam_id)


# Kick this player
# Should only work if you are the host or vote-kicking is enabled
func _on_kick_pressed():
	kick_player.emit(steam_id)


# View this player's profile on Steam
func _on_view_pressed() -> void:
	Steam.activateGameOverlayToUser("steamid", steam_id)


#################################################
# CALLBACKS
#################################################

# Load an avatar
func on_avatar_loaded(id: int, this_size: int, buffer: PackedByteArray) -> void:
	# Check we're only triggering a load for the right player, and check the data has actually changed
	if id == steam_id and (not user_avatar or not buffer == user_avatar.get_data()):
		print("Loading avatar for user: "+str(id))
		# Create the image and texture for loading
		user_avatar = Image.create_from_data(this_size, this_size, false, Image.FORMAT_RGBA8, buffer)
		# Apply it to the texture
		var avatar_texture: ImageTexture = ImageTexture.create_from_image(user_avatar)
		# Set it
		avatar_rect.set_texture(avatar_texture)

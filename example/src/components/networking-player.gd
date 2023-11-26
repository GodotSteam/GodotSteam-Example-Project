extends KinematicBody2D

export var gravity: int = 50
export var jump_force: int = 1000
export var max_fall_speed: int = 1000
export var move_speed: int = 500

 # Stored at the class level to enable comparisons when helper functions are called
var avatar: Image
# We expect a new packet every 100ms
var duration: float = 0.1
var facing_right: bool = false
# Determines if this instance of a player is "real" or not
var is_puppet: bool = false
var lerp_time: float = 0
# Default the steam_id of this player to be the hosts
var steam_id: int = Global.steam_id
var target_x: float = 0.0
var target_y: float = 0.0
var y_velocity: int = 0



func _ready() -> void:
	connect_networking_signals("movement", "_on_update_movement")
	connect_steam_signals("avatar_loaded", "_on_loaded_avatar")
	# If this player is the host, load the avatar now
	# Otherwise it will be requested later
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, steam_id)


func _physics_process(_delta: float) -> void:
	$SteamID.set_text(str(self.steam_id))

	var move_direction: int = 0
	if Input.is_action_pressed("move_right"):
		move_direction += 1
	if Input.is_action_pressed("move_left"):
		move_direction -= 1
	var _this_vector: Vector2 = move_and_slide(Vector2(move_direction * move_speed, y_velocity), Vector2(0, -1))

	var is_grounded: bool = is_on_floor()
	y_velocity += gravity
	if is_grounded and Input.is_action_just_pressed("jump"):
		y_velocity = -jump_force
	if is_grounded and y_velocity >= 5:
		y_velocity = 5
	if y_velocity > max_fall_speed:
		y_velocity = max_fall_speed
 
	if facing_right and move_direction < 0:
		flip()
	if !facing_right and move_direction > 0:
		flip()
 
	if is_grounded:
		if move_direction == 0:
			play_animation("idle")
		else:
			play_animation("walk")
	else:
		play_animation("jump")
 

#################################################
# PLAYER FUNCTIONS
#################################################
func flip() -> void:
	facing_right = !facing_right
	$Skin.flip_h = !$Skin.flip_h
 

func _on_loaded_avatar(this_id: int, this_size: int, this_buffer: PoolByteArray) -> void:
	# Check we're only triggering a load for the right player, and check the data has actually changed
	if this_id == steam_id and (not avatar or not this_buffer == avatar.get_data()):
		print("Loading avatar for user: %s" % this_id)
		# Create the image and texture for loading
		# Apply our image data from Steam then set the avatar texture
		avatar = Image.new()
		var avatar_texture: ImageTexture = ImageTexture.new()

		avatar.create_from_data(this_size, this_size, false, Image.FORMAT_RGBA8, this_buffer)
		avatar_texture.create_from_image(avatar)

		$Skin.set_texture(avatar_texture)


# Every 100ms this fires and sends a message with the position of this player
func _on_packet_timeout() -> void:
	if is_puppet:
		return
	var player_pos_data: Dictionary = {}
	player_pos_data['type'] = "movement"
	player_pos_data['x_pos'] = position.x
	player_pos_data['y_pos'] = position.y
	player_pos_data['player'] = Global.steam_id
	Networking.send_p2p_message('', player_pos_data)


# Responds to movement messages being received, check if this is for this player and apply
func _on_update_movement(payload: Dictionary) -> void:
	if payload['player'] != steam_id:
		if steam_id != Global.steam_id:
			print("Failed to parse this non-us payload %s" % payload)
			print("We had for our steam id: %s" % steam_id)
		return
	if not 'x_pos' in payload or not 'y_pos' in payload:
		print('Invalid movement message!')
		return 
	position.x = payload['x_pos']
	position.y = payload['y_pos']
	print("Changed position for %s to x:%s y:%s" % [steam_id, position.x, position.y])


func play_animation(animation_name: String) -> void:
	if $AnimationPlayer.is_playing() and $AnimationPlayer.current_animation == animation_name:
		return
	$AnimationPlayer.play(animation_name)


func request_player_avatar() -> void:
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, steam_id)


#################################################
# HELPER FUNCTIONS
#################################################
func connect_networking_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Networking.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])
	
	
func connect_steam_signals(this_signal: String, this_function: String) -> void:
	var signal_connect: int = Steam.connect(this_signal, self, this_function)
	if signal_connect > OK:
		print("Connecting %s to %s failed: %s" % [this_signal, this_function, signal_connect])

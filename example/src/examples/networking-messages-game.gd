extends Node2D
#################################################
# NETWORKING MESSAGES GAME
# A simple game to test networking messages
#################################################
onready var network_player = preload("res://src/components/networking-player.tscn")


func _ready() -> void:
	spawn_players()


func _process(_delta: float) -> void:
	# Get packets only if lobby is joined
	if Networking.lobby_id > 0:
		Networking.read_p2p_messages()


func spawn_players() -> void:
	print(Networking.lobby_members)
	for this_member in Networking.lobby_members:
		print(this_member)

		if this_member['steam_id'] == Global.steam_id or this_member.get('player_object', null):
			# Skip ourselves or skip if we already have a player object
			continue
		var fake_player: Object = instance_node_at_location(network_player, self, Vector2(675, 575))
		print('Instanced player')
		this_member['player_object'] = fake_player
		fake_player.is_puppet = true
		fake_player.steam_id = this_member['steam_id']
		fake_player.request_player_avatar()


# Instance a node at a specific global position. Used to spawn players.
# Returns a reference to the new node. 
func instance_node_at_location(this_node: Object, this_parent: Object, this_location: Vector2) -> Object:
	var node_instance: Object = instance_node(this_node, this_parent)
	node_instance.position = this_location
	return node_instance


# Instance a node as a child of parent. Return a reference to the new child.
func instance_node(this_node: Object, this_parent: Object) -> Object:
	var node_instance: Object = this_node.instance()
	this_parent.add_child(node_instance)
	return node_instance

extends Node

const PORT = 9000
const MAX_PLAYERS = 200

const LOBBY_PATH = "/root/Main/Game/Lobby"
const WORLD_PATH = "/root/Main/Game/World"

var server : NetworkedMultiplayerENet

var Client = preload("res://game_server/remote_client/RemoteClient.tscn")

var connected_clients = {}

func _ready():
	server = NetworkedMultiplayerENet.new()
	if server.create_server(PORT, MAX_PLAYERS) != 0: printerr("Failed to create server")

	get_tree().set_network_peer(server)

	var _r # prefix _ to get rid of 'var not used' warning. No need to use this var
	_r = get_tree().connect("network_peer_connected", self, "_client_connected")
	_r = get_tree().connect("network_peer_disconnected", self, "_client_disconnected")

func _client_connected(id):
	print("Client '%s' connected" % str(id))
	
	# Create a client node and rename it to its peer_id.
	var client = Client.instance()
	client.set_name(str(id))
	client.peer_id = id
	
	# Connect to the client's state_changed
	client.connect("state_changed", self, "_on_client_state_changed")
	
	# Then add it to the Lobby and set connected state. 
	get_node("/root/Main/Game/Lobby").add_child(client)
	client.set_state(Globals.ClientState.CONNECTED)
	
	# Also add it to the convenient connected_clients dictionary for easy access
	connected_clients[id] = client

func _client_disconnected(id):
	print("Client '%s' disconnected" % str(id))
	connected_clients[id].free()
	connected_clients.erase(id)

func _on_client_state_changed(peer_id, new_state):
	match new_state:
		# Client Logged in and should enter world
		Globals.ClientState.ENTERING_WORLD:
			# Sanity check 
			if (connected_clients[peer_id].get_parent().get_path() 
				!= LOBBY_PATH):
				push_error("Something went wrong. Client should be in the Lobby.")
				
			# Move client to World node.
			get_node(LOBBY_PATH).remove_child(connected_clients[peer_id])
			get_node(WORLD_PATH).add_child(connected_clients[peer_id])

		Globals.ClientState.IN_WORLD:
			pass

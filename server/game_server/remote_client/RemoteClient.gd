extends Node2D


# Just for readability (same as name)
var peer_id : int

var loginToken : String

var client_state = Globals.ClientState.DISCONNECTED setget use_set_state

signal state_changed(peer_id, new_state)


func set_state(new_state):
	rpc_id(peer_id, "set_client_state", new_state)
	emit_signal("state_changed", peer_id, new_state)
	client_state = new_state


remote func request_enter_world():
	# Would probably want to do more checks here later
	if client_state == Globals.ClientState.LOGGED_IN:
		set_state(Globals.ClientState.ENTERING_WORLD)

remote func entered_world():
	if client_state == Globals.ClientState.ENTERING_WORLD:
		set_state(Globals.ClientState.IN_WORLD)

######################################################
# Refactor to a login handler/manager under the client

remote func request_login(username: String, password: String):
	print("Got login request from client '%s'" % peer_id)
	
	# Send login request to the REST API. Only connect signal the first time the
	# client tries to log in.
	if !$HttpClient.auth.is_connected("login_complete", self, "_on_login_complete"):
		$HttpClient.auth.connect("login_complete", self, "_on_login_complete")

	var json = JSON.print({"username": username, "password": password})
	$HttpClient.auth.login(json)
	

# Signal from routes/auth
func _on_login_complete(successful, token, error):
	if successful:
		loginToken = token
		set_state(Globals.ClientState.LOGGED_IN)
	else:
		rpc_id(peer_id, "login_fail", error)


func use_set_state(_new_state):
	push_error(
		"Can't set the state directly. " +
		"Use set_state(client_id, new_state) instead"
		)

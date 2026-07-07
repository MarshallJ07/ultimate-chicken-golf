extends Node

const PLAYER_CONTROLLER = preload("uid://bs72ogkvdd7d6")
const BALL = preload("uid://lcpwgxrnd7nb")

var players: Array[CharacterBody3D]
var playerNames = {}

func _ready():
	Networking.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_peer_connected)


func _on_host_created():
	# Host spawns itself
	spawn_player.rpc(multiplayer.get_unique_id())


func _peer_connected(peer_id:int):
	if !multiplayer.is_server():
		return

	# Tell everyone to spawn the new player
	spawn_player.rpc(peer_id)

	# Tell the new client about everyone already in the game
	for p in players:
		var id = int(p.name.trim_prefix("player_"))
		if id != peer_id:
			spawn_player.rpc_id(peer_id, id)


@rpc("authority","call_local","reliable")
func spawn_player(peer_id:int):

	if has_node(str(peer_id)):
		return

	var player := PLAYER_CONTROLLER.instantiate()
	player.name = str(peer_id)

	add_child(player)
	initialize_player(player)

	var ball := BALL.instantiate()
	ball.name = str(peer_id)

	$balls.add_child(ball)
	initialize_ball(ball)

	getName.rpc_id(peer_id, peer_id)


@rpc("any_peer","call_local","reliable")
func getName(peer_id:int):
	sendNameToHost.rpc_id(1,Steam.getPersonaName(),peer_id)


@rpc("any_peer","call_local","reliable")
func sendNameToHost(playerName:String,peer_id:int):

	playerNames[str(peer_id)] = playerName
	sendNametags.rpc(playerNames)


@rpc("any_peer","call_local","reliable")
func sendNametags(playerNameList):

	for key in playerNameList.keys():
		var p = get_node_or_null(key)

		if p:
			p.get_node("nametag").text = playerNameList[key]


func initialize_player(player:CharacterBody3D):

	player.position = $SpawnPoint.position

	for other in players:
		player.add_collision_exception_with(other)
		other.add_collision_exception_with(player)

	players.append(player)


func initialize_ball(ball:RigidBody3D):

	ball.position = $SpawnPoint.position


func _on_host_pressed():
	Networking.host_lobby()
	$CanvasLayer/Host.disabled = true

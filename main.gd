extends Node

const PLAYER_CONTROLLER = preload("uid://bs72ogkvdd7d6")
const BALL = preload("uid://lcpwgxrnd7nb")

var players: Array[CharacterBody3D]
var ids: Array[int]
var playerNames = {}


func _ready():
	Networking.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_peer_connected)


func _on_host_created():
	add_player_pfp_and_name(Steam.getSteamID())

@rpc("any_peer","call_local","reliable")
func add_player_pfp_and_name(steam_id) -> void:
	print('getting pfp and name')
	var avatar = Steam.getMediumFriendAvatar(steam_id)
	if avatar > 0:
		pass
		
	var data = Steam.getImageRGBA(avatar)
		
	var image = Image.create_from_data(
	Steam.getImageSize(avatar)["width"],
	Steam.getImageSize(avatar)["height"],
	false,
	Image.FORMAT_RGBA8,
	 data["buffer"]
	)
	$CanvasLayer/pfpsAndNames.add_child(HBoxContainer.new())
	
	var rect = TextureRect.new()
	var label = Label.new()
	
	$CanvasLayer/pfpsAndNames.get_child(-1).add_child(rect)
	$CanvasLayer/pfpsAndNames.get_child(-1).add_child(label)
	var texture = ImageTexture.create_from_image(image)
	rect.texture = texture
	label.text = Steam.getPersonaName()

func _peer_connected(peer_id:int):
	if !multiplayer.is_server():
		if $CanvasLayer.has_node("start"):
			print('sent rpc')
			add_player_pfp_and_name.rpc(Steam.getSteamID())
			$CanvasLayer/start.queue_free()
			$CanvasLayer/Host.queue_free()
			$CanvasLayer/waiting.show()
		return
	
	ids.append(peer_id)
	




@rpc("authority","call_local","reliable")
func spawn_player(peer_id:int):
	$CanvasLayer/waiting.hide()
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
	$CanvasLayer/Host.disabled = true
	Networking.host_lobby()

func _on_start_pressed() -> void:
	if !multiplayer.is_server():
		return
	spawn_player.rpc(multiplayer.get_unique_id())
	for id in ids:
		spawn_player.rpc(id)
	
	

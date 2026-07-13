extends Node

const PLAYER_CONTROLLER = preload("uid://bs72ogkvdd7d6")
const BALL = preload("uid://lcpwgxrnd7nb")

var players: Array[CharacterBody3D]
var ids: Array[int]
var playerNames = {}
var playerPfpsAndNames = []

var gameState = "choosing"
var playersDonePlacingObstacles = 0
var spawnOrder: int

var points := 0

var obstacles = {
	"sandTrap":{"text":"sandTrap"},
	"wall":{"text":"wall"},
	"funnel":{"text":"funnel"},
}
var ghost: Node3D
var currentObstacle = null


func _ready():
	Networking.host_created.connect(_on_host_created)
	multiplayer.peer_connected.connect(_peer_connected)


func _on_host_created():
	spawnOrder = 0
	print('host')
	add_player_pfp_and_name(Steam.getSteamID(),Steam.getPersonaName(),1)
@rpc("any_peer","call_local","reliable")
func add_player_pfp_and_name(steam_id, playerName, peer_id) -> void:
	var sender = multiplayer.get_remote_sender_id()
	print("RPC was sent by peer:", sender,'  peer_id: ',peer_id)
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
	
	$CanvasLayer/Scoreboard.get_node("players").add_child(preload("res://scenes/scoreboard_player.tscn").instantiate())

	


	
	
	var texture = ImageTexture.create_from_image(image)
	rect.texture = texture
	label.text = playerName
	
	$CanvasLayer/Scoreboard.get_node("players").get_child(-1).get_child(0).get_node("text").text = playerName
	$CanvasLayer/Scoreboard.get_node("players").get_child(-1).get_child(0).get_node("icon").texture = texture
	$CanvasLayer/Scoreboard.get_node("players").get_child(-1).name = str(peer_id)
	
		
	
	if multiplayer.is_server():
		playerPfpsAndNames.append([steam_id, playerName])
		
@rpc("any_peer","call_local","reliable")
func _get_spawn_order(num:int) -> void:
	spawnOrder = num
		
func _peer_connected(peer_id:int):
	add_player_pfp_and_name.rpc_id(peer_id,Steam.getSteamID(),Steam.getPersonaName(),multiplayer.get_unique_id())
	if multiplayer.is_server():
		_get_spawn_order.rpc_id(peer_id,playerPfpsAndNames.size())

	if !multiplayer.is_server():
		if $CanvasLayer.has_node("start"):
			add_player_pfp_and_name(Steam.getSteamID(),Steam.getPersonaName(),multiplayer.get_unique_id())
			$CanvasLayer/start.queue_free()
			$CanvasLayer/Host.queue_free()
			$CanvasLayer/waiting.show()
		return
	
	ids.append(peer_id)
	




@rpc("authority","call_local","reliable")
func spawn_player(peer_id:int):
	$CanvasLayer/waiting.hide()
	var strokeName = Label.new()
	strokeName.name = str(peer_id)
	get_node("CanvasLayer").get_node("strokes").add_child(strokeName)
	if has_node(str(peer_id)):
		return

	var player := PLAYER_CONTROLLER.instantiate()
	player.name = str(peer_id)

	add_child(player)
	initialize_player(player)

	var ball := BALL.instantiate()
	ball.name = str(peer_id)

	$balls.add_child(ball)

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

	player.global_position = $SpawnPoints.get_child(spawnOrder).global_position

	for other in players:
		player.add_collision_exception_with(other)
		other.add_collision_exception_with(player)

	players.append(player)


func initialize_ball(ball:RigidBody3D):
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_position = $SpawnPoints.get_child(spawnOrder).global_position 
	ball.global_position[0] += 1
	ball.global_position[2] -= 0.2

func _on_host_pressed():
	$CanvasLayer/Host.disabled = true
	Networking.host_lobby()

func _on_start_pressed() -> void:
	if !multiplayer.is_server():
		return
	spawn_player.rpc(multiplayer.get_unique_id())
	for id in ids:
		spawn_player.rpc(id)
		
	get_choices.rpc()
	hideButtons.rpc()
	
@rpc("any_peer","call_local","reliable")
func hideButtons() -> void:
	if multiplayer.is_server():
		$CanvasLayer/Host.hide()
	$CanvasLayer/pfpsAndNames.hide()
	
	
@rpc("any_peer","call_local","reliable")
func get_choices() -> void:
	if multiplayer.is_server():
		playersDonePlacingObstacles = 0
	$CanvasLayer/obstacleChoices.show()
	for choice in $CanvasLayer/obstacleChoices.get_children():
		var randomNumber = randi() % obstacles.size()
		var tempObstacle = obstacles.keys()[randomNumber]
		choice.text = obstacles[tempObstacle]["text"]
			


func _on_choice_1_pressed() -> void:
	currentObstacle = $CanvasLayer/obstacleChoices/choice1.text
	choice_button_pressed()
func _on_choice_2_pressed() -> void:
	currentObstacle = $CanvasLayer/obstacleChoices/choice2.text
	choice_button_pressed()
func _on_choice_3_pressed() -> void:
	currentObstacle = $CanvasLayer/obstacleChoices/choice3.text
	choice_button_pressed()

func choice_button_pressed() -> void:
	gameState = "game"
	ghost = get_node(str(multiplayer.get_unique_id())).get_ghost_obstacle("res://scenes/"+currentObstacle+".tscn")
	$CanvasLayer/obstacleChoices.hide()
	get_node(str(multiplayer.get_unique_id())).capture_mouse()
	get_node(str(multiplayer.get_unique_id())).building = true
	
@rpc("any_peer","call_local","reliable")
func send_object_placed_to_host() -> void:
	playersDonePlacingObstacles += 1
	if playersDonePlacingObstacles == players.size():
		_transition.rpc()
		
@rpc("any_peer","call_local","reliable")
func _scoreboard() -> void:
	$CanvasLayer/Scoreboard.show()


@rpc("any_peer","call_local","reliable")
func _transition() -> void:
	$CanvasLayer/black.modulate.a = 0
	var tween = create_tween()
	tween.tween_property($CanvasLayer/black,"modulate:a",1,2)
	tween.finished.connect(_countdown)

func _start():
	
	get_node(str(multiplayer.get_unique_id())).can_move = true
	if !multiplayer.is_server():
		$CanvasLayer/ColorRect.show()
		$CanvasLayer/ColorRect2.show()
	
	
	
	





func _countdown() -> void:
	
	if $CanvasLayer/countdown/countdown.text == "0":
		$CanvasLayer/countdown/Timer.start()
		$CanvasLayer/countdown.show()
		
		get_node(str(multiplayer.get_unique_id())).can_move = false
		get_node(str(multiplayer.get_unique_id())).building = false
		get_node(str(multiplayer.get_unique_id())).freeflying = false
		initialize_ball($balls.get_node(str(multiplayer.get_unique_id())))
		get_node(str(multiplayer.get_unique_id())).global_position = $SpawnPoints.get_child(spawnOrder).global_position
		
		$CanvasLayer/black.modulate.a = 1
		var tween = create_tween()
		tween.tween_property($CanvasLayer/black,"modulate:a",0,2)
		$CanvasLayer/countdown/countdown.text = "3"
	elif $CanvasLayer/countdown/countdown.text == "1":
		$CanvasLayer/countdown/countdown.text = "0"
		$CanvasLayer/countdown.hide()
		_start()
	elif $CanvasLayer/countdown/countdown.text == "2":
		$CanvasLayer/countdown/Timer.start()
		$CanvasLayer/countdown/countdown.text = "1"
	elif $CanvasLayer/countdown/countdown.text == "3":
		$CanvasLayer/countdown/Timer.start()
		$CanvasLayer/countdown/countdown.text = "2"
	

extends Node


const PLAYER_CONTROLLER = preload("uid://bs72ogkvdd7d6")
var players: Array[CharacterBody3D]

func _ready() -> void:
	Networking.host_created.connect(on_host_created)
	
func on_host_created() -> void:
	spawn_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(spawn_player)
	
func spawn_player(peer_id:int) -> void:
	var new_player := PLAYER_CONTROLLER.instantiate() as CharacterBody3D
	new_player.name = str(peer_id)
	add_child(new_player)
	initialize_player(new_player)
	
	var ball = preload("res://scenes/ball.tscn").instantiate()
	ball.name = str(peer_id)
	$balls.add_child(ball)
	initialize_ball(ball)
func initialize_player(player: CharacterBody3D) -> void:
	player.position = $SpawnPoint.position
	for other in players:
		player.add_collision_exception_with(other)
	players.append(player)

func initialize_ball(ball: RigidBody3D) -> void:
	ball.position = $SpawnPoint.position
	


func _on_host_pressed() -> void:
	Networking.host_lobby()


func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is CharacterBody3D:
		initialize_player(node)
	if node is RigidBody3D:
		initialize_ball(node)

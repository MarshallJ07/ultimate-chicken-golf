extends Node

const PLAYER_SCENE := preload("uid://bs72ogkvdd7d6")
const BALL_SCENE := preload("res://scenes/ball.tscn")

var players: Array[CharacterBody3D] = []

func _ready() -> void:
	Networking.host_created.connect(_on_host_created)

func _on_host_created() -> void:
	print("Host created")

	# Spawn the host.
	_spawn_player(multiplayer.get_unique_id())

	# Spawn future clients.
	multiplayer.peer_connected.connect(_spawn_player)

func _spawn_player(peer_id: int) -> void:
	if !multiplayer.is_server():
		return

	print("Spawning", peer_id)

	# Player
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.global_position = $SpawnPoint.global_position
	add_child(player)

	for other in players:
		player.add_collision_exception_with(other)
	players.append(player)

	# Ball
	var ball := BALL_SCENE.instantiate()
	ball.name = "Ball_%d" % peer_id
	ball.owner_peer_id = peer_id
	ball.global_position = $SpawnPoint.global_position
	$balls.add_child(ball)

func _on_host_pressed() -> void:
	Networking.host_lobby()

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	print("Replicated:", node.name)

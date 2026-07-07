extends RigidBody3D


var id: int

	
func _ready() -> void:
	$Timer.start()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	follow_ragdoll_everywhere.rpc_id(1)
	
@rpc("any_peer","call_local","reliable")
func follow_ragdoll_everywhere() -> void:
	get_parent().get_node(str(multiplayer.get_unique_id())).position = position

func _on_timer_timeout() -> void:
	if not is_multiplayer_authority():
		return
	reset_character.rpc_id(1)
	reset_character_everywhere.rpc(1)
	
@rpc("any_peer","call_local","reliable")
func reset_character() -> void:
	get_parent().get_node(str(multiplayer.get_unique_id())).position = position
	get_parent().get_node(str(multiplayer.get_unique_id())).externalVelocity = linear_velocity
	
@rpc("any_peer","call_local","reliable")
func reset_character_everywhere() -> void:
	get_parent().get_node(str(multiplayer.get_unique_id())).get_node("Collider").disabled = false
	get_parent().get_node(str(multiplayer.get_unique_id())).get_node("Mesh").show()
	queue_free()

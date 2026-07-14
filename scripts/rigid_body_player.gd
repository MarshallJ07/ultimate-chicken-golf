extends RigidBody3D


var id: int

	
func _ready() -> void:
	if not is_multiplayer_authority():
		get_child(0).freeze = true
	$Timer.start()

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		send_host_position.rpc(global_position)
	
	
		
@rpc("any_peer","call_local", "reliable")
func send_host_position(hostPos) -> void:
	if is_multiplayer_authority():
		get_parent().get_parent().get_node(str(id)).global_position = global_position
		if linear_velocity.length() < 0.5 and $Timer.is_stopped():
			ask_is_slow_enough.rpc_id(1,id)

#HOST
@rpc("call_local", "reliable")
func ask_is_slow_enough(peer_id) -> void:
	if is_multiplayer_authority() and peer_id == id:
		if linear_velocity.length() < 0.5:
			remove_all_ragdolls.rpc(id)
	
#EVERYONE
@rpc("any_peer","call_local", "reliable")
func remove_all_ragdolls(peer_id) -> void:
	if peer_id == id:
		get_parent().get_parent().get_node(str(id)).show()
		get_parent().get_parent().get_node(str(id)).can_move = true
		get_parent().get_parent().get_node(str(id)).can_use_action = true
		queue_free()


func _on_timer_timeout() -> void:
	$Timer.stop()

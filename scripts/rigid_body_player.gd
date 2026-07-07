extends RigidBody3D


var id: int

	
func _ready() -> void:
	$Timer.start()
	set_multiplayer_authority(1)
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	follow_ragdoll_everywhere.rpc_id(id)

#CALLED ON HOST
@rpc("any_peer","call_local","reliable")
func follow_ragdoll_everywhere(ragdollID) -> void:
	if id == ragdollID:
		print('moved ragdoll cam')
		get_parent().get_node(str(id)).global_position = global_position

func _on_timer_timeout() -> void:
	if not is_multiplayer_authority():
		return
	reset_character_everywhere.rpc(id)
	
@rpc("any_peer","call_local","reliable")
func reset_character_everywhere(ragdollID) -> void:
	if id == ragdollID:
		get_parent().get_node(str(id)).externalVelocity = linear_velocity
		get_parent().get_node(str(id)).get_node("Collider").disabled = false
		get_parent().get_node(str(id)).get_node("Mesh").show()
	if not is_multiplayer_authority():
		return
	get_parent().get_node(str(id)).position = position
	
	queue_free()


func _on_multiplayer_synchronizer_synchronized() -> void:
	if id != 1 and not is_multiplayer_authority():
		print('synchonized')

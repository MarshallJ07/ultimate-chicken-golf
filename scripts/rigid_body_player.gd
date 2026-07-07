extends RigidBody3D


var id: int

	
func _ready() -> void:
	$Timer.start()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	follow_ragdoll_everywhere.rpc(id)
	
@rpc("any_peer","call_local","reliable")
func follow_ragdoll_everywhere(ragdollID) -> void:
	if not is_multiplayer_authority():
		return
	if not id == ragdollID:
		return
	get_parent().get_node(str(multiplayer.get_unique_id())).position = position

func _on_timer_timeout() -> void:
	if not is_multiplayer_authority():
		return
	reset_character_everywhere.rpc(id)
	
@rpc("any_peer","call_local","reliable")
func reset_character_everywhere(ragdollID) -> void:
	if id == ragdollID:
			get_parent().get_node(str(multiplayer.get_unique_id())).externalVelocity = linear_velocity
			get_parent().get_node(str(multiplayer.get_unique_id())).get_node("Collider").disabled = false
			get_parent().get_node(str(multiplayer.get_unique_id())).get_node("Mesh").show()
	if not is_multiplayer_authority():
		return
	get_parent().get_node(str(multiplayer.get_unique_id())).position = position
	
	queue_free()

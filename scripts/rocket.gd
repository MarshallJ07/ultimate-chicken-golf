extends Node3D

var id:int



func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	if not is_multiplayer_authority():
		get_child(0).freeze = true



func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body.name != get_parent().get_parent().get_node(str(id)).name and body.name != $rocketCollider.name:
		explode_everywhere.rpc(id)
	
	
#EVERYONE
@rpc("any_peer", "call_local", "reliable")
func explode_everywhere(peer_id) -> void:
	if id == peer_id:
		$explosion.position = $rocketCollider.position
		$explosion.restart()
		if is_multiplayer_authority():
			check_player_collisions.rpc_id(1,id)
		
		
#HOST
@rpc("any_peer", "call_local", "reliable")
func check_player_collisions(peer_id) -> void:
	if id != peer_id:
		return
	var space_state = get_world_3d().direct_space_state

	# Create an explosion sphere
	var sphere = SphereShape3D.new()
	sphere.radius = 5.0 # <-- Change to your explosion radius

	# Create the query
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(
		Basis.IDENTITY,
		$rocketCollider.global_position
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	# Optional: only detect your player collision layer
	# query.collision_mask = 1 << PLAYER_LAYER

	var results = space_state.intersect_shape(query)

	for result in results:
		var body = result.collider

		if body is CharacterBody3D:
			print("Hit:", body.name)
			create_ragdoll_everywhere.rpc(body.name.to_int())
			
	$rocketCollider.queue_free()
	
#EVERYONE
@rpc("any_peer", "call_local", "reliable")
func create_ragdoll_everywhere(peer_id) -> void:
	if id != peer_id:
		return
	var ragdoll = preload("res://scenes/rigidBodyPlayer.tscn").instantiate()
	ragdoll.id = id
	get_parent().get_parent().get_node("ragdolls").add_child(ragdoll)
	get_parent().get_parent().get_node(str(id)).add_collision_exception_with(ragdoll)
	ragdoll.add_collision_exception_with(get_parent().get_parent().get_node(str(id)))
	
	get_parent().get_parent().get_node(str(id)).hide()
	get_parent().get_parent().get_node(str(id)).can_move = false
	get_parent().get_parent().get_node(str(id)).can_use_action = false
	if is_multiplayer_authority():
		ragdoll.position = get_parent().get_parent().get_node(str(id)).position
		ragdoll.apply_impulse((get_parent().get_parent().get_node(str(id)).get_node("Head").global_position - $rocketCollider.global_position).normalized() * 30)
		

func _on_explosion_finished() -> void:
	queue_free()

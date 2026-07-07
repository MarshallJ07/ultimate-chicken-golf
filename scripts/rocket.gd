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
		$rocketCollider.queue_free()
		await get_tree().physics_frame
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
			
func _on_explosion_finished() -> void:
	queue_free()

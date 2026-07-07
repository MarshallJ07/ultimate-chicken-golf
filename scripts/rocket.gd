extends Node3D



func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(name.to_int())

func _on_area_3d_body_entered(body: Node3D) -> void:
	
	if body != get_parent().get_parent().get_node(str(name)) and body != $rocketCollider:
		
		$rocketCollider/explosion.restart()
		$rocketCollider/explosion.emitting = true
		$rocketCollider/Area3D.queue_free()
		$rocketCollider/MeshInstance3D.queue_free()
		await get_tree().process_frame
		get_collisions()
		
		
func get_collisions() -> void:
	for hit in $rocketCollider/explosion/explosion.get_overlapping_bodies():
		print(hit)
		if hit is CharacterBody3D:
			get_parent().get_parent().get_node(str(hit.name)).hide()
			var ragdoll = preload("res://scenes/rigidBodyPlayer.tscn").instantiate()
			get_parent().get_parent().add_child(ragdoll)
			ragdoll.position = get_parent().get_parent().get_node(str(name)).position
			ragdoll.apply_impulse((get_parent().get_parent().get_node(str(ragdoll.name)).position - $rocketCollider/explosion/explosion.position).normalized() * 10)

func _on_explosion_finished() -> void:
	queue_free()


func get_bodies_in_radius(center: Vector3, radius: float = 3.0) -> Array:
	var sphere := SphereShape3D.new()
	sphere.radius = radius

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis(), center)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [self] # Optional

	var results = get_world_3d().direct_space_state.intersect_shape(query)

	var hits: Array = []

	for result in results:
		var body = result.collider
		var direction = (body.global_position - center).normalized()

		hits.append({
			"body": body,
			"direction": direction
		})

	return hits

extends Node3D

var id:int

func getPosition() -> void:
	print(position)

func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body != get_parent().get_parent().get_node(str(id)) and body != $rocketCollider:
		print(body)
		$rocketCollider/explosion.restart()
		print($rocketCollider/explosion.position)
		emit_particles_everywhere.rpc()
		$rocketCollider/CollisionShape3D.queue_free()
		$rocketCollider/Area3D.queue_free()
		$rocketCollider/MeshInstance3D.queue_free()
		get_collisions.rpc_id(1)
		
@rpc("any_peer","call_local","reliable")
func get_collisions() -> void:
	for hit in $rocketCollider/explosion/explosion.get_overlapping_bodies():
		if hit is CharacterBody3D:
			print(hit.name)
			create_ragdoll_everywhere.rpc(hit.name)
			
			
@rpc("any_peer","call_local","reliable")
func create_ragdoll_everywhere(hit) -> void:
	var ragdoll
	if str(id) == str(hit):
		get_parent().get_parent().get_node(str(hit)).get_node("Mesh").hide()
		get_parent().get_parent().get_node(str(hit)).get_node("Collider").disabled = true
		ragdoll = preload("res://scenes/rigidBodyPlayer.tscn").instantiate()
		ragdoll.id = id
		get_parent().get_parent().add_child(ragdoll)
	if not is_multiplayer_authority():
		return
	if id == multiplayer.get_unique_id():
		ragdoll.position = get_parent().get_parent().get_node(str(id)).position
		ragdoll.apply_impulse((get_parent().get_parent().get_node(str(hit)).global_position - $rocketCollider/explosion/explosion.global_position).normalized() * 40)

func _on_explosion_finished() -> void:
	queue_free()
@rpc("any_peer","call_local","reliable")
func emit_particles_everywhere() -> void:
	$rocketCollider/explosion.emitting = true

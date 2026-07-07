extends Node3D

var id:int



func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
	if not is_multiplayer_authority():
		get_child(0).freeze = true
func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body != get_parent().get_parent().get_node(str(id)) and body != $rocketCollider:
		$rocketCollider/explosion.restart()
		emit_particles_everywhere.rpc()
		$rocketCollider/CollisionShape3D.queue_free()
		$rocketCollider/Area3D.queue_free()
		$rocketCollider/MeshInstance3D.queue_free()
		get_collisions.rpc_id(1,id)


#CALLED ON HOST
@rpc("any_peer","call_local","reliable")
func get_collisions(peer_id) -> void:
	if not id == peer_id:
		return
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
		get_parent().get_parent().get_node("ragdolls").add_child(ragdoll)
		if not is_multiplayer_authority():
			return
		ragdoll.global_position = get_parent().get_parent().get_node(str(id)).global_position
		ragdoll.apply_impulse((get_parent().get_parent().get_node(str(hit)).global_position - $rocketCollider/explosion/explosion.global_position).normalized() * 40)

func _on_explosion_finished() -> void:
	queue_free()
@rpc("any_peer","call_local","reliable")
func emit_particles_everywhere() -> void:
	$rocketCollider/explosion.emitting = true

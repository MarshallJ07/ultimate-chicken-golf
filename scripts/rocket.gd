extends Node3D

var id:int

func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
func _on_area_3d_body_entered(body: Node3D) -> void:
	if not is_multiplayer_authority():
		return
	if body != get_parent().get_parent().get_node(str(id)) and body != $rocketCollider:
		
		$rocketCollider/explosion.restart()
		$rocketCollider/explosion.emitting = true
		$rocketCollider/Area3D.queue_free()
		$rocketCollider/MeshInstance3D.queue_free()
		get_collisions()
		
		
func get_collisions() -> void:
	for hit in $rocketCollider/explosion/explosion.get_overlapping_bodies():
		if hit is CharacterBody3D:
			get_parent().get_parent().get_node(str(hit.name)).hide()
			var ragdoll = preload("res://scenes/rigidBodyPlayer.tscn").instantiate()
			get_parent().get_parent().add_child(ragdoll)
			ragdoll.position = get_parent().get_parent().get_node(str(id)).position
			ragdoll.apply_impulse((get_parent().get_parent().get_node(str(ragdoll.name)).position - $rocketCollider/explosion/explosion.position).normalized() * 10)

func _on_explosion_finished() -> void:
	queue_free()

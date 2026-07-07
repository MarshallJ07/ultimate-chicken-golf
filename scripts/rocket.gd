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



func _on_explosion_finished() -> void:
	queue_free()

extends Node3D
@export var owner_peer_id := -1
func _physics_process(delta: float) -> void:
	if get_child(2).is_colliding():
		self.linear_damp = 2
		self.angular_damp = 2
	else:
		self.linear_damp = 0
		self.angular_damp = 0
func _enter_tree() -> void:
	set_multiplayer_authority(owner_peer_id)

extends Node3D

func _physics_process(delta: float) -> void:
	if get_child(2).is_colliding():
		self.linear_damp = 2
		self.angular_damp = 2
	else:
		self.linear_damp = 0
		self.angular_damp = 0

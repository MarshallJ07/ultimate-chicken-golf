extends RigidBody3D


var id: int

	
func _ready() -> void:
	$Timer.start()
	set_multiplayer_authority(1)

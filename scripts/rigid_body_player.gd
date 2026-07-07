extends RigidBody3D


var id: int

	
func _ready() -> void:
	$Timer.start()

func _physics_process(delta: float) -> void:
	get_parent().get_node(str(multiplayer.get_unique_id())).position = position

func _on_timer_timeout() -> void:
	get_parent().get_node(str(multiplayer.get_unique_id())).position = position
	get_parent().get_node(str(multiplayer.get_unique_id())).externalVelocity = linear_velocity
	get_parent().get_node(str(multiplayer.get_unique_id())).get_node("Collider").disabled = false
	get_parent().get_node(str(multiplayer.get_unique_id())).get_node("Mesh").show()
	queue_free()

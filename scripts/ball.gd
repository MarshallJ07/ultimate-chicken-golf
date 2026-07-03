extends RigidBody3D
@export var owner_peer_id := -1
func _physics_process(delta: float) -> void:
	for i in get_node("raycasts").get_children():
		if i.is_colliding():
			self.linear_damp = 6
			self.angular_damp = 6
			break
		else:
			self.linear_damp = 0
			self.angular_damp = 3
			break
		
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
func _ready() -> void:
	get_parent().get_parent().get_node("Hole").body_entered.connect(_body_entered)
	
func _body_entered(node):
	if node != self:
		return
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").show()
	print(name)
	winnerText.rpc_id(1)
	

@rpc("any_peer","call_local","reliable")
func winnerText() -> void:
	if !multiplayer.is_server():
		return
	print(name)
	displayText.rpc(get_parent().get_parent().playerNames[name.to_int()]+" Wins")
	
@rpc("any_peer","call_local","reliable")
func displayText(text) -> void:
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").get_node("winText").text = text
	
	

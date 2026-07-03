extends RigidBody3D

var collisionLayers = {
	"sandTrap":10
}
var modifierDamp = 0
var modifierAngularDamp = 0



func _physics_process(delta: float) -> void:
	self.linear_damp = 0
	self.angular_damp = 0
	var collided = false
	for i in get_node("raycasts").get_children():
		if i.is_colliding():
			self.linear_damp += 2 + modifierDamp
			self.angular_damp += 3 + modifierAngularDamp
			modifierDamp = 0
			modifierAngularDamp = 0
			break

	
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
func _ready() -> void:
	get_parent().get_parent().get_node("Hole").body_entered.connect(_body_entered)
	
func _body_entered(node):
	if node != self:
		return
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").show()
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
	
	


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.get_collision_layer_value(collisionLayers["sandTrap"]):
		modifierDamp += 30
		modifierAngularDamp += 30

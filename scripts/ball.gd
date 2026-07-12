extends RigidBody3D

var collisionLayers = {
	"sandTrap":10,
	"grass":1
}
var collidedWith = {
	"sandTrap":0,
	"grass":0
}
var modifierDamp = 0
var modifierAngularDamp = 0

var player
func _physics_process(delta: float) -> void:
	modifierDamp = 0
	modifierAngularDamp = 0
	collidedWith = {
	"sandTrap":0,
	"grass":0
	}
	for area in get_node("Area3D").get_overlapping_areas():
		if area.get_collision_layer_value(collisionLayers["sandTrap"]) and collidedWith["sandTrap"] == 0:
			collidedWith["sandTrap"] = 1
			modifierDamp += 10
			modifierAngularDamp += 10
			player.swingPower *= 0.4
	for body in get_node("Area3D").get_overlapping_bodies():
		if body.get_collision_layer_value(collisionLayers["grass"]) and collidedWith["grass"] == 0:
			collidedWith["grass"] = 1
			modifierDamp += 2
			modifierAngularDamp += 2
	
	self.linear_damp = modifierDamp
	self.angular_damp = modifierAngularDamp

	
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
func _ready() -> void:
	player = get_parent().get_parent().get_node(str(name.to_int()))
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
	print(get_parent().get_parent().playerNames)
	print(name)
	print('name  ',get_parent().get_parent().playerNames[str(name.to_int())]+" Wins")
	get_parent().get_node('1').displayText.rpc(get_parent().get_parent().playerNames[str(name.to_int())]+" Wins")
	
	
	
	
@rpc("any_peer","call_local","reliable")
func displayText(text) -> void:
	if not is_multiplayer_authority():
		return
	print('auth   ',name)
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").get_node("winText").text = text
	get_parent().get_parent().get_node("winParticles").restart()
	get_parent().get_parent().get_node("winParticles").finished.connect(_particles_finished)
func _particles_finished() -> void:
	var tween = create_tween()
	get_parent().get_parent().get_node("CanvasLayer").get_node("black").modulate.a = 0
	tween.tween_property(get_parent().get_parent().get_node("CanvasLayer").get_node("black"),"modulate:a",1,2)
	tween.finished.connect(_reset)
	
func _reset() -> void:
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").hide()
	
	get_parent().get_parent().get_choices()
	
	get_parent().get_parent().get_node(str(name)).position = get_parent().get_parent().get_node("SpawnPoints").get_child(get_parent().get_parent().spawnOrder).position
	get_parent().get_parent().get_node(str(name)).release_mouse()
	get_parent().get_parent().get_node(str(name)).building = false
	get_parent().get_parent().get_node(str(name)).freeflying = true
	var tween = create_tween()
	get_parent().get_parent().get_node("CanvasLayer").get_node("black").modulate.a = 1
	tween.tween_property(get_parent().get_parent().get_node("CanvasLayer").get_node("black"),"modulate:a",0,2)

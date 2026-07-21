extends RigidBody3D

var collisionLayers = {
	"sandTrap":10,
	"grass":1,
	"ice":11
}
var collidedWith = {
	"sandTrap":0,
	"grass":0,
	"ice":0
}
var modifierDamp = 0
var modifierAngularDamp = 0

var player
func _physics_process(delta: float) -> void:
	modifierDamp = 0
	modifierAngularDamp = 0
	physics_material_override.friction = 0.6
	collidedWith = {
	"sandTrap":0,
	"grass":0,
	"ice":0
	}
	for area in get_node("Area3D").get_overlapping_areas():
		if area.get_collision_layer_value(collisionLayers["sandTrap"]) and collidedWith["sandTrap"] == 0:
			collidedWith["sandTrap"] = 1
			modifierDamp += 10
			modifierAngularDamp += 10
			player.swingPower *= 0.4
		elif area.get_collision_layer_value(collisionLayers["ice"]) and collidedWith["ice"] == 0:
			collidedWith["ice"] = 1
			player.is_on_ice = true
			modifierDamp -= 2
			physics_material_override.friction = 0.0
	for body in get_node("Area3D").get_overlapping_bodies():
		if body.get_collision_layer_value(collisionLayers["grass"]) and collidedWith["grass"] == 0:
			collidedWith["grass"] = 1
			modifierAngularDamp += 2
			modifierDamp += 2
			var speed = linear_velocity.length()
			if speed < 1.0:
				modifierDamp += 4.0
				modifierAngularDamp += 4.0
			if speed < 0.5:
				modifierDamp += 6.0
				modifierAngularDamp += 6.0
			if linear_velocity.length() < 0.25:
				linear_velocity = Vector3.ZERO
				angular_velocity = Vector3.ZERO
			
	
	
	self.linear_damp = modifierDamp
	self.angular_damp = modifierAngularDamp
	
	
	
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	
func _ready() -> void:
	player = get_parent().get_parent().get_node(str(name.to_int()))
	get_parent().get_parent().get_node("Hole").body_entered.connect(_body_entered)
	
func _body_entered(node):
	if node != self or !multiplayer.is_server():
		return
	

	winnerText.rpc_id(1)
	

@rpc("any_peer","call_local","reliable")
func winnerText() -> void:
	if !multiplayer.is_server():
		return
	send_to_auths.rpc(get_parent().get_parent().playerNames[str(name.to_int())]+" Wins",str(name))
	
@rpc("any_peer","call_local","reliable")
func send_to_auths(text: String, playerName: String) -> void:
	get_parent().get_node(str(multiplayer.get_unique_id())).displayText(text,playerName)
	

func displayText(text:String,playerName:String) -> void:
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").show()
	for i in get_parent().get_parent().get_node("CanvasLayer").get_node("Scoreboard").get_node("players").get_node(playerName).get_node("HBoxContainer2").get_children():
		if !i.visible:
			i.show()
			break
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").get_node("winText").text = text
	get_parent().get_parent().get_node("winParticles").restart()
	get_parent().get_parent().get_node("winParticles").finished.connect(_particles_finished)
func _particles_finished() -> void:
	var tween = create_tween()
	get_parent().get_parent().get_node("CanvasLayer").get_node("black").modulate.a = 0
	tween.tween_property(get_parent().get_parent().get_node("CanvasLayer").get_node("black"),"modulate:a",1,2)
	tween.finished.connect(_reset)
	
func _reset() -> void:
	if !get_multiplayer_authority():
		return
	get_parent().get_parent().get_node("CanvasLayer").get_node("Panel").hide()
	
	get_parent().get_parent().get_node(str(name)).global_position = get_parent().get_parent().get_node("SpawnPoints").get_child(get_parent().get_parent().spawnOrder).global_position
	get_parent().get_parent().get_node(str(name)).release_mouse()
	get_parent().get_parent().get_node(str(name)).building = false
	get_parent().get_parent().get_node(str(name)).freeflying = true
	get_parent().get_parent().get_node(str(name)).can_move = false
	
	var tween = create_tween()
	get_parent().get_parent().get_node("CanvasLayer").get_node("black").modulate.a = 1
	tween.tween_property(get_parent().get_parent().get_node("CanvasLayer").get_node("black"),"modulate:a",0,2)
	get_parent().get_parent()._scoreboard.rpc()

# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = true
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = true

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 30.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to shoot
@export var input_shoot : String = "shoot"

@export var input_new_ball : String = "input_new_ball"

@export var item1 : String = "item 1"
@export var item2 : String = "item 2"
@export var item3 : String = "item 3"
@export var item4 : String = "item 4"


var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = true
var building : bool = true

var items := ["club","rpg",null,null]
var itemActionFuncs := {
	"club":"actionClub",
	"rpg":"actionRPG"
}
var currentItem: String = "club"

var itemScenes := {
	"club":preload("res://scenes/golf_club.tscn"),
	"rpg":preload("res://scenes/rpg.tscn")
}

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var camera = $Head/Camera3D

#CREATE DEBUG SANDTRAP
var ghostSandTrap = preload("res://scenes/sand_trap.tscn").instantiate()

#SHOT VARIABLES
var swingPower = 1

func _ready():
	set_multiplayer_authority(name.to_int())

	$Head/Camera3D.current = is_multiplayer_authority()

	# everything else already in your _ready()
	#CREATE DEBUG SANDTRAP
	get_parent().get_node("ghost obstacles").add_child(ghostSandTrap)
	var material = ghostSandTrap.get_child(0).get_active_material(0).duplicate()
	ghostSandTrap.get_child(0).set_surface_override_material(0, material)
	material.albedo_color.a = 0.1
	
	var club = itemScenes[currentItem].instantiate()
	get_node("item").add_child(club)
	club.rotation.y = deg_to_rad(270)
	
	
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	

		
@rpc("any_peer", "call_local", "reliable")
func _spawn_ball_everywhere(power: int,ball):
	var dir = -camera.global_transform.basis.z + Vector3.UP * 0.8
	var up = camera.global_transform.basis.y
	var final_dir = (dir + up * 0.1).normalized()
	for i in get_parent().get_node("balls").get_children():
		if i.name.to_int() == int(ball):
			get_node("item").get_node("golfClub").get_node("swing").play("swing")
			await get_tree().create_timer(0.65).timeout
			if i in get_node("ballZone").get_overlapping_bodies():
				i.apply_impulse(final_dir * power * swingPower)

func _shoot(power: int,node):
	if multiplayer.is_server():
		for i in get_parent().get_node("balls").get_children():
			if i.name.to_int() == int(node):
				_spawn_ball_everywhere.rpc(power,name)
				break
	else:
		shoot_rpc.rpc_id(1,power,name)

@rpc("any_peer")
func shoot_rpc(power: int, node):
	for i in get_parent().get_node("balls").get_children():
		if i.name.to_int() == int(node):
			_spawn_ball_everywhere.rpc(power,name)
			break
	
	
	
	
	
@rpc("any_peer", "call_local", "reliable")
func _spawn_rocket_everywhere(peer_id):
	if not is_multiplayer_authority():
		return
	var dir = -camera.global_transform.basis.z.normalized()

	var rocket = preload("res://scenes/rocket.tscn").instantiate()
	get_parent().get_node("bullets").add_child(rocket)

	rocket.global_position = get_parent().get_node(str(peer_id)).global_position
	rocket.look_at(get_parent().get_node(str(peer_id)).global_position + dir, Vector3.UP)
	print(name)
	rocket.name = str(peer_id)
	if multiplayer.get_unique_id() == 1:
		rocket.get_child(0).apply_central_impulse(-rocket.global_transform.basis.z * 100)

func _shootRPG():
	_shootRPG_rpc.rpc_id(1,multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func _shootRPG_rpc(peer_id):
	_spawn_rocket_everywhere.rpc(peer_id)
	

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()

	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()


func _get_new_ball() -> void:
	for i in get_parent().get_node("balls").get_children():
		if i.name.to_int() == int(name):
			i.position = position
			i.linear_velocity = Vector3.ZERO
			i.angular_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
			
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		if building:
		
			var mouse_pos = get_viewport().get_mouse_position()

			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * 1000

			var space = get_world_3d().direct_space_state

			var query = PhysicsRayQueryParameters3D.create(from, to)
			var result = space.intersect_ray(query)
			if result:
				ghostSandTrap.position = result.position
			if Input.is_action_just_pressed(input_shoot):
				place_obstacle.rpc_id(1,"res://scenes/sand_trap.tscn",result.position)
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity
			
	if Input.is_action_just_pressed(item1):
		currentItem = "club"
		if get_node("item").get_child(0) != null:
			get_node("item").get_child(0).free()
		var club = itemScenes[currentItem].instantiate()
		get_node("item").add_child(club)
		club.rotation.y = deg_to_rad(270)
	if Input.is_action_just_pressed(item2):
		if items[1] != null:
			currentItem = items[1]
			if get_node("item").get_child(0) != null:
				get_node("item").get_child(0).free()
			get_node("item").add_child(itemScenes[currentItem].instantiate())
	if Input.is_action_just_pressed(item3):
		if items[2] != null:
			currentItem = items[2]
			if get_node("item").get_child(0) != null:
				get_node("item").get_child(0).free()
			get_node("item").add_child(itemScenes[currentItem].instantiate())
	if Input.is_action_just_pressed(item4):
		if items[3] != null:
			currentItem = items[3]
			if get_node("item").get_child(0) != null:
				get_node("item").get_child(0).free()
			get_node("item").add_child(itemScenes[currentItem].instantiate())

	if Input.is_action_just_pressed(input_shoot):
		if currentItem != null:
			call(itemActionFuncs[currentItem])
		
	if Input.is_action_just_pressed(input_new_ball):
		_get_new_ball()
	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
			move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()


@rpc("any_peer","call_local","reliable")
func place_obstacle(obstacle,pos) -> void:
	place_obstacle_client.rpc(obstacle,pos)
	
@rpc("any_peer","call_local","reliable")
func place_obstacle_client(obstacle,pos) -> void:
	var sandTrap = load(obstacle).instantiate()
	get_parent().get_node("obstacles").add_child(sandTrap)
	sandTrap.position = pos
	


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false


func actionClub() -> void:
	if !get_node("item").get_node("golfClub").get_node("swing").is_playing() and get_node("item").get_node("golfClub").get_node("swing").current_animation != "swing":
		_shoot(30, name)
		
func actionRPG() -> void:
	_shootRPG()

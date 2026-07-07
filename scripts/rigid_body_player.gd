extends RigidBody3D

## Look around rotation speed.
@export var look_speed : float = 0.002


@export var item1 : String = "item 1"
@export var item2 : String = "item 2"
@export var item3 : String = "item 3"
@export var item4 : String = "item 4"

var id: int

var mouse_captured : bool = true
var look_rotation : Vector2

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



func _unhandled_input(event: InputEvent) -> void:

	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
func _ready() -> void:
	$Head/Camera3D.make_current()
	$Timer.start()

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



func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


func _on_timer_timeout() -> void:
	get_parent().get_node(str(id)).position = position
	get_parent().get_node(str(id)).show()
	get_parent().get_node(str(id)).get_node("Head").get_node("Camera3D").make_current()
	queue_free()

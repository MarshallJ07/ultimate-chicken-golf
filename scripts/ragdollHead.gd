extends Node3D

@onready var camera := $Camera3D

@export var camera_offset := Vector3(1, 1, 4.0)
@export var collision_radius := 0.3
@export var smooth_speed := 15.0
@export var collision_mask := 1

func _physics_process(delta):
	var from = global_position
	var desired = global_transform * camera_offset

	var shape := SphereShape3D.new()
	shape.radius = collision_radius

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), from)
	query.motion = desired - from
	query.collision_mask = collision_mask
	query.exclude = [get_parent()] # Player

	var result = get_world_3d().direct_space_state.cast_motion(query)

	var final_pos = desired

	if result.size() > 0:
		var safe_fraction = result[0]
		final_pos = from.lerp(desired, safe_fraction * 0.95)

	camera.position = camera.position.lerp(
		to_local(final_pos),
		smooth_speed * delta
	)

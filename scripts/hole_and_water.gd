extends Node3D

var image: Image
var mask_texture: ImageTexture

@onready var terrain := $Plane
@onready var material := terrain.get_active_material(0) as ShaderMaterial


func _ready():
	create_mask()
	create_sand_trap(Vector3(0,0,0))

func create_mask():
	# Grayscale mask
	image = Image.create(1024, 1024, false, Image.FORMAT_RF)

	# Start as grass
	image.fill(Color.WHITE)

	mask_texture = ImageTexture.create_from_image(image)

	material.set_shader_parameter("mask_texture", mask_texture)

	# Assign your textures
	material.set_shader_parameter(
		"grass_texture",
		load("res://textures/grass.jpg")
	)

	material.set_shader_parameter(
		"sand_texture",
		load("res://textures/sand.jpg")
	)


func create_sand_trap(world_position: Vector3, radius := 30):
	# Change this depending on your island size
	var island_size = 100.0

	var uv = Vector2(
		(world_position.x + island_size / 2.0) / island_size,
		(world_position.z + island_size / 2.0) / island_size
	)

	var pixel = Vector2i(
		uv.x * image.get_width(),
		uv.y * image.get_height()
	)


	for x in range(pixel.x - radius, pixel.x + radius):
		for y in range(pixel.y - radius, pixel.y + radius):

			if x < 0 or x >= image.get_width():
				continue
			if y < 0 or y >= image.get_height():
				continue

			var distance = Vector2(x, y).distance_to(pixel)

			if distance < radius:
				var t = pow(distance / radius, 3.0)
				image.set_pixel(x, y, Color(t, t, t))



	mask_texture.update(image)

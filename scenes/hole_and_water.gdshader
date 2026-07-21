shader_type spatial;

uniform sampler2D mask_texture;
uniform sampler2D grass_texture;
uniform sampler2D sand_texture;

uniform float texture_scale = 10.0;

void fragment() {
	float mask = texture(mask_texture, UV).r;

	vec3 grass = texture(grass_texture, UV * texture_scale).rgb;
	vec3 sand = texture(sand_texture, UV * texture_scale).rgb;

	// White mask = grass
	// Black mask = sand
	ALBEDO = mix(sand, grass, mask);
}
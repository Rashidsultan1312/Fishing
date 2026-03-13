shader_type canvas_item;

uniform vec4 color_surface : source_color = vec4(0.2, 0.6, 0.9, 1.0);
uniform vec4 color_deep : source_color = vec4(0.02, 0.05, 0.15, 1.0);
uniform float depth_offset = 0.0;
uniform float max_depth = 2000.0;
uniform float wave_speed = 0.5;
uniform float wave_amplitude = 0.01;
uniform float ray_intensity = 0.15;

void fragment() {
	float depth_ratio = clamp((depth_offset + UV.y * 1920.0) / max_depth, 0.0, 1.0);
	vec4 bg = mix(color_surface, color_deep, depth_ratio);

	float wave = sin(UV.x * 20.0 + TIME * wave_speed) * wave_amplitude;
	wave += sin(UV.x * 35.0 - TIME * wave_speed * 0.7) * wave_amplitude * 0.5;
	bg.rgb += wave * (1.0 - depth_ratio);

	float ray = sin(UV.x * 8.0 + TIME * 0.3) * 0.5 + 0.5;
	ray *= sin(UV.x * 12.0 - TIME * 0.2) * 0.5 + 0.5;
	ray *= (1.0 - depth_ratio) * ray_intensity;
	ray *= (1.0 - UV.y);
	bg.rgb += vec3(ray);

	float bubble = step(0.998, sin(UV.x * 100.0 + TIME) * sin(UV.y * 80.0 - TIME * 2.0));
	bg.rgb += bubble * 0.3 * (1.0 - depth_ratio * 0.5);

	COLOR = bg;
}

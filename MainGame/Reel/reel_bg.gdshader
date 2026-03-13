shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.05, 0.2, 0.4, 0.92);
uniform vec4 color_bottom : source_color = vec4(0.01, 0.04, 0.12, 0.96);
uniform float ray_intensity : hint_range(0.0, 0.4) = 0.1;
uniform float time_scale : hint_range(0.0, 2.0) = 0.25;

void fragment() {
	vec4 bg = mix(color_top, color_bottom, UV.y);

	float ray1 = smoothstep(0.45, 0.0, abs(UV.x - 0.25 - sin(TIME * time_scale) * 0.06)) * (1.0 - UV.y);
	float ray2 = smoothstep(0.4, 0.0, abs(UV.x - 0.6 + sin(TIME * time_scale * 0.7 + 1.5) * 0.05)) * (1.0 - UV.y);
	float ray3 = smoothstep(0.35, 0.0, abs(UV.x - 0.85 + cos(TIME * time_scale * 0.5 + 3.0) * 0.04)) * (1.0 - UV.y * 1.2);
	float rays = (ray1 + ray2 + ray3) * ray_intensity;
	bg.rgb += vec3(rays * 0.4, rays * 0.7, rays);

	float vignette = 1.0 - smoothstep(0.4, 1.2, length((UV - 0.5) * vec2(1.4, 1.0)));
	bg.rgb *= mix(0.6, 1.0, vignette);

	COLOR = bg;
}

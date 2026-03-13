shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float ripple_strength : hint_range(0.0, 0.1) = 0.03;
uniform float ripple_freq : hint_range(1.0, 30.0) = 12.0;
uniform float ripple_speed : hint_range(1.0, 20.0) = 8.0;
uniform vec4 flash_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic : hint_range(0.0, 0.02) = 0.0;
uniform float vignette_strength : hint_range(0.0, 2.0) = 0.0;
uniform float zoom : hint_range(0.0, 0.2) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5, 0.7);

	uv = mix(uv, center, zoom);

	float dist = distance(uv, center);
	float ripple = sin(dist * ripple_freq * 3.14159 - TIME * ripple_speed) * ripple_strength * progress;
	ripple *= smoothstep(0.5, 0.0, dist);
	vec2 off = normalize(uv - center + 0.001) * ripple;

	float r = textureLod(screen_tex, uv + off + vec2(chromatic, 0.0), 0.0).r;
	float g = textureLod(screen_tex, uv + off, 0.0).g;
	float b = textureLod(screen_tex, uv + off - vec2(chromatic, 0.0), 0.0).b;
	vec3 col = vec3(r, g, b);

	float vig = 1.0 - smoothstep(0.3, 0.9, dist) * vignette_strength;
	col *= vig;

	col = mix(col, flash_color.rgb, flash_intensity);

	COLOR = vec4(col, 1.0);
}

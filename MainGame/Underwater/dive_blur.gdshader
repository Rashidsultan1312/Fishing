shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic : hint_range(0.0, 0.015) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5);
	vec2 dir = normalize(uv - center + 0.001);
	float dist = distance(uv, center);

	float r = textureLod(screen_tex, uv + dir * chromatic, 0.0).r;
	float g = textureLod(screen_tex, uv, 0.0).g;
	float b = textureLod(screen_tex, uv - dir * chromatic, 0.0).b;
	vec3 col = vec3(r, g, b);

	float streak = sin(uv.x * 50.0 + TIME * 4.0) * 0.5 + 0.5;
	streak *= sin(uv.x * 30.0 - TIME * 2.0) * 0.5 + 0.5;
	streak = mix(1.0, streak, 0.5);
	float vfade = smoothstep(0.0, 0.15, uv.y) * smoothstep(1.0, 0.85, uv.y);
	float alpha = intensity * vfade * streak * 0.9;
	vec3 water_col = mix(vec3(0.7, 0.9, 1.0), vec3(0.05, 0.2, 0.5), uv.y);

	col = mix(col, water_col, alpha);

	COLOR = vec4(col, 1.0);
}

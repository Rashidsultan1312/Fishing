shader_type canvas_item;

uniform vec4 sky_top : source_color = vec4(0.4, 0.7, 1.0, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.2, 0.4, 0.8, 1.0);
uniform vec4 water_color : source_color = vec4(0.1, 0.3, 0.6, 1.0);
uniform vec4 terrain_color : source_color = vec4(0.2, 0.5, 0.2, 1.0);
uniform float time_scale : hint_range(0.1, 2.0) = 0.5;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.1;
		amp *= 0.5;
	}
	return val;
}

void fragment() {
	vec2 uv = UV;
	float horizon = 0.5;

	vec4 sky = mix(sky_top, sky_bottom, smoothstep(0.0, horizon, uv.y));

	float cloud_x = uv.x * 4.0 + TIME * time_scale * 0.06;
	float cloud = fbm(vec2(cloud_x, uv.y * 3.0));
	cloud = smoothstep(0.4, 0.7, cloud) * 0.35 * smoothstep(horizon, 0.0, uv.y);
	sky.rgb += cloud;

	float sun_dist = length((uv - vec2(0.75, 0.15)) * vec2(1.0, 1.5));
	sky.rgb += smoothstep(0.35, 0.0, sun_dist) * 0.3 * mix(vec3(1.0, 0.9, 0.6), sky_top.rgb, 0.3);

	float ix = (uv.x - 0.5) * 2.0;
	float hb = horizon - 0.02;
	float h1 = hb - 0.15 * exp(-ix * ix * 2.0);
	float h2 = hb - 0.1 * exp(-(ix - 0.6) * (ix - 0.6) * 4.0);
	float h3 = hb - 0.08 * exp(-(ix + 0.5) * (ix + 0.5) * 3.0);
	float h4 = hb - 0.04 * exp(-(ix - 0.3) * (ix - 0.3) * 8.0);
	float island_line = min(min(h1, h2), min(h3, h4)) + noise(uv * vec2(15.0, 8.0)) * 0.015;

	float island_mask = smoothstep(island_line + 0.003, island_line - 0.003, uv.y) * step(uv.y, horizon + 0.01);

	vec4 terrain = terrain_color;
	terrain.rgb *= 0.75 + fbm(uv * 12.0) * 0.3;
	terrain.rgb *= 0.7 + 0.3 * smoothstep(island_line - 0.1, island_line, uv.y);

	float tree_x = uv.x * 8.0;
	float tree_line = island_line - 0.02 - 0.03 * abs(sin(tree_x * 3.0 + 0.5)) - 0.015 * noise(vec2(tree_x * 2.0, 0.0));
	float tree_mask = smoothstep(tree_line + 0.005, tree_line - 0.005, uv.y) * island_mask;
	vec3 tree_col = terrain_color.rgb * vec3(0.6, 0.8, 0.5) * (0.5 + 0.5 * noise(uv * 20.0));

	float wt = TIME * time_scale;
	float water_line = horizon + sin(uv.x * 18.0 + wt * 2.0) * 0.004 + sin(uv.x * 30.0 - wt * 1.5) * 0.002 + sin(uv.x * 50.0 + wt * 3.0) * 0.001;
	float water_mask = smoothstep(water_line - 0.003, water_line + 0.003, uv.y);

	vec4 water = water_color;
	float wd = clamp((uv.y - horizon) / (1.0 - horizon), 0.0, 1.0);
	water.rgb *= 1.0 - wd * 0.6;
	water.rgb += (sin(uv.x * 45.0 + wt * 3.5) * 0.5 + 0.5) * (sin(uv.x * 70.0 - wt * 2.5) * 0.5 + 0.5) * (1.0 - wd) * 0.1;
	water.rgb += smoothstep(0.015, 0.0, abs(uv.y - water_line)) * (0.6 + 0.4 * sin(uv.x * 30.0 + wt)) * 0.3;

	float refl_y = 2.0 * horizon - uv.y;
	float refl_mask = smoothstep(island_line + 0.003, island_line - 0.003, refl_y) * step(refl_y, horizon);
	water.rgb = mix(water.rgb, terrain.rgb * 0.5, refl_mask * smoothstep(horizon + 0.2, horizon, uv.y) * 0.25);

	vec4 col = sky;
	col.rgb = mix(col.rgb, terrain.rgb, island_mask);
	col.rgb = mix(col.rgb, tree_col, tree_mask * 0.7);
	col.rgb = mix(col.rgb, water.rgb, water_mask);

	float vignette = 1.0 - smoothstep(0.5, 1.3, length((uv - 0.5) * vec2(1.2, 1.0)));
	col.rgb *= mix(0.7, 1.0, vignette);

	COLOR = col;
}

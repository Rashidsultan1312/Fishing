shader_type canvas_item;

uniform vec2 pan_speed = vec2(0.1, 0.0); // UV movement per second
uniform vec2 tile_scale = vec2(1.0, 1.0); // how many times the texture tiles

void fragment() {
    vec2 uv = UV;

    // Apply tiling
    uv *= tile_scale;

    // Apply panning
    uv += pan_speed * TIME;

    // Wrap UVs so texture repeats
    uv = fract(uv);

    COLOR = texture(TEXTURE, uv);
}

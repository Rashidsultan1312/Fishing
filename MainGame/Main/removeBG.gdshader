shader_type canvas_item;

// The target color to remove (green)
uniform vec3 key_color : source_color = vec3(0.0, 1.0, 0.0);

// How strict the removal is (0–1)
uniform float threshold : hint_range(0.0, 1.0) = 0.3;

// Soft edges (fade between removed and kept)
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Compute "greenish-ness"
    float green_factor = tex.g - max(tex.r, tex.b);

    // Create alpha based on how green it is
    float alpha = 1.0;
    if (green_factor > threshold) {
        alpha = smoothstep(threshold, threshold + smoothness, green_factor);
        alpha = 1.0 - alpha; // invert to remove green
    }

    COLOR = vec4(tex.rgb, tex.a * alpha);
}

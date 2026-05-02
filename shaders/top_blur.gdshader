shader_type canvas_item;

#include "res://shaders/crt_base.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 5.0) = 4.0;
uniform float edge_margin : hint_range(0.0, 1.0) = 0.2;
uniform vec4 tint_color : source_color = vec4(0.1, 0.1, 0.1, 0.4);

void fragment() {
    vec2 safe_uv;
    float outside_amount;
    calculate_crt_uv(SCREEN_UV, TIME, safe_uv, outside_amount);

    // --- Edge blur mask ---
    float left = safe_uv.x;
    float right = 1.0 - safe_uv.x;
    float top = safe_uv.y;
    float bottom = 1.0 - safe_uv.y;
    float min_dist = min(min(left, right), min(top, bottom));
    float edge_mask = clamp(1.0 - (min_dist / edge_margin), 0.0, 1.0);
    edge_mask = edge_mask * edge_mask * (3.0 - 2.0 * edge_mask); // smoothstep

    float combined_mask = max(edge_mask, outside_amount);

    // --- Sampling ---
    vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 sampling_uv = get_pixelated_uv(safe_uv, res, pixel_size);
    float lod = blur_strength * combined_mask;
    vec3 color = sample_crt_color(screen_texture, sampling_uv, lod, chroma_strength);

    // --- Finalize ---
    vec4 final_color = mix(vec4(color, 1.0), tint_color, combined_mask * 0.4);
    final_color.rgb = apply_crt_effects(final_color.rgb, safe_uv, res);

    COLOR = vec4(final_color.rgb, 1.0);
}

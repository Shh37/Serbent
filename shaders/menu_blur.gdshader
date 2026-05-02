shader_type canvas_item;

#include "res://shaders/crt_base.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest_mipmap;
uniform float blur_strength : hint_range(0.0, 5.0) = 4.0;
uniform float edge_margin : hint_range(0.0, 1.0) = 0.25;
uniform vec4 tint_color : source_color = vec4(0.1, 0.1, 0.1, 0.4);

// Title blur region (in UV space: 0..1)
uniform vec2 title_center = vec2(0.5, 0.38);
uniform vec2 title_size = vec2(0.5, 0.14);
uniform float title_falloff : hint_range(0.0, 0.5) = 0.08;

// Button blur region (in UV space: 0..1)
uniform vec2 button_center = vec2(0.5, 0.62);
uniform vec2 button_size = vec2(0.22, 0.1);
uniform float button_falloff : hint_range(0.0, 0.5) = 0.06;

// How much blur for the UI regions (relative to blur_strength)
uniform float ui_blur_intensity : hint_range(0.0, 1.5) = 1.0;

float rect_mask(vec2 uv, vec2 center, vec2 half_size, float falloff) {
    vec2 d = abs(uv - center) - half_size;
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    return 1.0 - smoothstep(0.0, falloff, dist);
}

void fragment() {
    vec2 safe_uv;
    float outside_amount;
    calculate_crt_uv(SCREEN_UV, TIME, safe_uv, outside_amount);

    // --- Masks ---
    float left = safe_uv.x;
    float right = 1.0 - safe_uv.x;
    float top = safe_uv.y;
    float bottom = 1.0 - safe_uv.y;
    float min_dist = min(min(left, right), min(top, bottom));
    float edge_mask = clamp(1.0 - (min_dist / edge_margin), 0.0, 1.0);
    edge_mask = edge_mask * edge_mask * (3.0 - 2.0 * edge_mask);
    edge_mask = max(edge_mask, outside_amount);

    // UI element blur masks (use original UV since UI elements are screen-space)
    float title_mask = rect_mask(UV, title_center, title_size * 0.5, title_falloff);
    float button_mask = rect_mask(UV, button_center, button_size * 0.5, button_falloff);
    float ui_mask = max(title_mask, button_mask);

    float combined_mask = max(edge_mask, ui_mask);
    float blur_amount = max(edge_mask * blur_strength, ui_mask * blur_strength * ui_blur_intensity);

    // --- Sampling ---
    vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 sampling_uv = get_pixelated_uv(safe_uv, res, pixel_size);
    vec3 color = sample_crt_color(screen_texture, sampling_uv, blur_amount, chroma_strength);

    // --- Tint ---
    float tint_amount = min(edge_mask * 0.4 + ui_mask * 0.25, 0.45);
    vec4 final_color = mix(vec4(color, 1.0), tint_color, tint_amount);

    // --- Post process ---
    final_color.rgb = apply_crt_effects(final_color.rgb, safe_uv, res);

    COLOR = vec4(final_color.rgb, 1.0);
}

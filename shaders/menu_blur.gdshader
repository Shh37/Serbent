shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
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
    // Signed distance from rectangle edge (negative = inside)
    vec2 d = abs(uv - center) - half_size;
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);

    // Smooth falloff: 1.0 inside, fading to 0.0 at falloff distance
    return 1.0 - smoothstep(0.0, falloff, dist);
}

void fragment() {
    // --- Edge blur mask (same as top_blur.gdshader) ---
    float left = UV.x;
    float right = 1.0 - UV.x;
    float top = UV.y;
    float bottom = 1.0 - UV.y;
    float min_dist = min(min(left, right), min(top, bottom));
    float edge_mask = clamp(1.0 - (min_dist / edge_margin), 0.0, 1.0);
    edge_mask = edge_mask * edge_mask * (3.0 - 2.0 * edge_mask); // smoothstep

    // --- UI element blur masks ---
    float title_mask = rect_mask(UV, title_center, title_size * 0.5, title_falloff);
    float button_mask = rect_mask(UV, button_center, button_size * 0.5, button_falloff);
    float ui_mask = max(title_mask, button_mask);

    // --- Combine masks: use max so they don't stack/interfere ---
    float combined_mask = max(edge_mask, ui_mask);

    // --- Blur intensity: edge uses blur_strength, UI uses scaled version ---
    float blur_amount = max(edge_mask * blur_strength, ui_mask * blur_strength * ui_blur_intensity);

    // --- Apply blur ---
    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount);

    // --- Tint: edge gets full tint, UI regions get softer tint ---
    float tint_amount = edge_mask * 0.4 + ui_mask * 0.25;
    // Avoid double-tinting where edge and UI overlap
    tint_amount = min(tint_amount, 0.45);

    vec4 final_color = mix(blurred, tint_color, tint_amount);

    COLOR = vec4(final_color.rgb, 1.0);
}

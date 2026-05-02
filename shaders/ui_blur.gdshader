shader_type canvas_item;

#include "res://shaders/crt_base.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 10.0) = 4.0;
uniform vec4 tint_color : source_color = vec4(0.05, 0.05, 0.05, 0.6);

void fragment() {
    // We use the CRT UV logic so it respects distortion and glitch if needed, 
    // but primarily to get the same sampling behavior as the rest of the game.
    vec2 safe_uv;
    float outside_amount;
    calculate_crt_uv(SCREEN_UV, TIME, safe_uv, outside_amount);

    // Get pixelated UV (if CRT is on) or normal UV (if off)
    vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 sampling_uv = get_pixelated_uv(safe_uv, res, pixel_size);

    // Sample using the same chromatic aberration + manual nearest logic
    vec3 color = sample_crt_color(screen_texture, sampling_uv, blur_amount, chroma_strength);

    // Apply tint
    vec3 final_color = mix(color, tint_color.rgb, tint_color.a);
    
    // Apply final CRT effects (vignette/scanlines) if desired on settings screen
    // We'll apply them to keep the look consistent
    final_color = apply_crt_effects(final_color, safe_uv, res);

    COLOR = vec4(final_color, 1.0);
}

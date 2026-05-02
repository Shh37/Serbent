// crt_base.gdshaderinc

// --- Uniforms ---
uniform float curvature : hint_range(0.0, 20.0) = 3.0;
uniform float chroma_strength : hint_range(0.0, 5.0) = 0.7;
uniform float glitch_intensity : hint_range(0.0, 0.1) = 0.01;
uniform float glitch_rate : hint_range(1.0, 30.0) = 2.0;
uniform float glitch_threshold : hint_range(0.0, 1.0) = 0.995;
uniform vec2 glitch_block_size = vec2(12.0, 8.0);
uniform float pixel_size : hint_range(1.0, 16.0) = 4.0;
uniform float scanline_intensity : hint_range(0.0, 0.2) = 0.05;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;

// --- Helper Functions ---
float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 barrel_distort(vec2 uv, float p_curvature) {
    vec2 centered = uv * 2.0 - 1.0;
    float r2 = dot(centered, centered);
    centered *= 1.0 + p_curvature * 0.01 * r2;
    return centered * 0.5 + 0.5;
}

// --- Common Logic ---

// Calculates the UV coordinates after glitch and barrel distortion
// Returns safe_uv (clamped) and outside_amount (for vignetting/blurring outside edges)
void calculate_crt_uv(vec2 screen_uv, float time, out vec2 safe_uv, out float outside_amount) {
    // 1. Block Glitch
    float time_slot = floor(time * glitch_rate);
    vec2 block_pos = floor(screen_uv * glitch_block_size);
    float block_rand = hash21(block_pos + time_slot);
    vec2 glitch_offset = vec2(0.0);
    if (block_rand > glitch_threshold) {
        float ox = hash21(block_pos * 7.13 + time_slot) * 2.0 - 1.0;
        float oy = hash21(block_pos * 3.71 + time_slot) * 2.0 - 1.0;
        glitch_offset = vec2(ox, oy) * glitch_intensity;
    }
    vec2 glitched_uv = screen_uv + glitch_offset;

    // 2. Barrel Distortion
    vec2 curved_uv = barrel_distort(glitched_uv, curvature);

    // 3. Edge calculations
    vec2 overshoot = max(vec2(0.0), max(-curved_uv, curved_uv - 1.0));
    outside_amount = clamp(length(overshoot) * 15.0, 0.0, 1.0);
    safe_uv = clamp(curved_uv, 0.0, 1.0);
}

// Quantizes UV for pixelation
vec2 get_pixelated_uv(vec2 uv, vec2 screen_res, float p_pixel_size) {
    vec2 pixel_grid = floor(uv * screen_res / p_pixel_size);
    return (pixel_grid + 0.5) * p_pixel_size / screen_res;
}

// Samples texture with chromatic aberration and blur (LOD)
vec3 sample_crt_color(sampler2D tex, vec2 uv, float lod, float p_chroma) {
    vec2 from_center = uv - 0.5;
    float dist_from_center = length(from_center);
    vec2 chroma_offset = from_center * p_chroma * 0.01 * (1.0 + dist_from_center * 3.0);

    float r = textureLod(tex, uv + chroma_offset, lod).r;
    float g = textureLod(tex, uv, lod).g;
    float b = textureLod(tex, uv - chroma_offset, lod).b;
    return vec3(r, g, b);
}

// Applies scanlines and vignette to the final RGB color
vec3 apply_crt_effects(vec3 color, vec2 uv, vec2 screen_res) {
    vec3 result = color;

    // Scanlines
    float scanline = sin(uv.y * screen_res.y * 1.5) * scanline_intensity;
    result -= scanline;

    // Radial Vignette
    float v_dist = length(uv - 0.5) * 1.414;
    float v_mask = smoothstep(0.5, 1.2, v_dist);
    result *= mix(1.0, 1.0 - vignette_intensity, v_mask * vignette_opacity);

    return result;
}

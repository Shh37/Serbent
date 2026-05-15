// crt_base.gdshaderinc

// --- Uniforms ---
uniform bool crt_enabled = true;

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
    if (!crt_enabled) {
        safe_uv = screen_uv;
        outside_amount = 0.0;
        return;
    }

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
    if (!crt_enabled) return uv;
    vec2 pixel_grid = floor(uv * screen_res / p_pixel_size);
    return (pixel_grid + 0.5) * p_pixel_size / screen_res;
}

// Samples texture with chromatic aberration and blur (LOD)
// When CRT is enabled, we interpolate between discrete LOD levels for a smooth blocky transition
vec3 sample_crt_color(sampler2D tex, vec2 uv, float lod, float p_chroma) {
    if (!crt_enabled) return textureLod(tex, uv, lod).rgb;

    float lod_f = floor(lod);
    float lod_c = ceil(lod);
    float f = fract(lod);

    // Sample floor LOD
    vec2 res_f = vec2(textureSize(tex, int(lod_f)));
    vec2 snap_f = (floor(uv * res_f) + 0.5) / res_f;
    vec2 off_f = (snap_f - 0.5) * p_chroma * 0.01 * (1.0 + length(snap_f - 0.5) * 3.0);
    vec3 col_f = vec3(
        textureLod(tex, snap_f + off_f, lod_f).r,
        textureLod(tex, snap_f, lod_f).g,
        textureLod(tex, snap_f - off_f, lod_f).b
    );

    // If lod is integer, just return floor sample
    if (f < 0.001) return col_f;

    // Sample ceil LOD
    vec2 res_c = vec2(textureSize(tex, int(lod_c)));
    vec2 snap_c = (floor(uv * res_c) + 0.5) / res_c;
    vec2 off_c = (snap_c - 0.5) * p_chroma * 0.01 * (1.0 + length(snap_c - 0.5) * 3.0);
    vec3 col_c = vec3(
        textureLod(tex, snap_c + off_c, lod_c).r,
        textureLod(tex, snap_c, lod_c).g,
        textureLod(tex, snap_c - off_c, lod_c).b
    );

    return mix(col_f, col_c, f);
}

// Applies scanlines and vignette to the final RGB color
vec3 apply_crt_effects(vec3 color, vec2 uv, vec2 screen_res) {
    if (!crt_enabled) return color;
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

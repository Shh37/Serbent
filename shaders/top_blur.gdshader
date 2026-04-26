shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 5.0) = 4.0;
uniform float edge_margin : hint_range(0.0, 1.0) = 0.2;
uniform vec4 tint_color : source_color = vec4(0.1, 0.1, 0.1, 0.4);

void fragment() {
    // Distance from each edge
    float left = UV.x;
    float right = 1.0 - UV.x;
    float top = UV.y;
    float bottom = 1.0 - UV.y;
    
    // Find the minimum distance to any edge
    float min_dist = min(min(left, right), min(top, bottom));
    
    // Calculate mask: 1.0 at edge, 0.0 at center (beyond margin)
    float mask = clamp(1.0 - (min_dist / edge_margin), 0.0, 1.0);
    
    // Smooth the mask
    mask = mask * mask * (3.0 - 2.0 * mask);
    
    // Apply blur using Lod
    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_strength * mask);
    
    // Mix with tint
    vec4 final_color = mix(blurred, tint_color, mask * 0.4);
    
    COLOR = vec4(final_color.rgb, 1.0);
}

shader_type canvas_item;

uniform float circle_diameter = 0.0;
uniform float pixel_size = 4.0; // ajusta esse valor

void fragment() {
    vec2 center = 1.0 / SCREEN_PIXEL_SIZE * 0.5;
    vec2 pixel_pos = floor(FRAGCOORD.xy / pixel_size) * pixel_size;
    
    float dist = distance(pixel_pos, center);
    if (dist < circle_diameter / 2.0) {
        discard;
    }
}

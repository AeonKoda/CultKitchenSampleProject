shader_type canvas_item;

uniform vec2 circle_center; // in screen coordinates
uniform float circle_radius; // in pixels
uniform vec2 control_size;
varying vec4 vertex_col;

void vertex() {
    vertex_col = COLOR; // Pass along the vertex color (usually white by default).
}

void fragment() {
    // Use FRAGCOORD.xy (screen pixel coordinates) for the current fragment.
    vec2 frag_pos = FRAGCOORD.xy;
	vec2 uv = FRAGCOORD.xy / control_size;
    float d = distance(frag_pos, circle_center);
    if (d > circle_radius) {
        discard;
    }
    COLOR = vertex_col;
}
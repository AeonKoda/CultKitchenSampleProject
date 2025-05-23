shader_type canvas_item;

uniform vec2 rect_position; // Top-left corner of the rectangle in local coordinates
uniform vec2 rect_size;     // Size of the rectangle

void fragment() {
	vec2 pos = FRAGCOORD.xy;
	if (pos.x > rect_position.x && pos.x < (rect_position.x + rect_size.x) &&
		pos.y > rect_position.y && pos.y < (rect_position.y + rect_size.y)) {
		 // Clip the sprite
	} else {
	discard;
	}
}

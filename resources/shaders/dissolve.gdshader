shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);
uniform bool reversed = false;
uniform vec2 diamondCount = vec2(12.0, 12.0); // diamonds across / down

void fragment() {
	vec2 cell = abs(fract(UV * diamondCount) - 0.5);
	float d = cell.x + cell.y;        // 0 .. 1
	if (reversed && (d + UV.x + UV.y < progress * 3.0)) {
		discard;
	} else if (!reversed && (d + UV.x + UV.y > progress * 3.0)) {
		discard;
	}
}
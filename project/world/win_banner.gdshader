shader_type canvas_item;

uniform int segments = 1;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform vec4 color4;

void fragment() {
	if (COLOR == vec4(1.0, 1.0, 1.0, 1.0)) {
		if (segments == 1) {
			COLOR = color1;
		} else if (segments == 2) {
			if (UV.x < 0.5) {
				COLOR = color1;
			} else {
				COLOR = color2;
			}
		} else if (segments == 3) {
			if ((UV.x + UV.y < 0.7) || (UV.x - UV.y > 0.3)) {
				COLOR = color1;
			} else if (UV.x < 0.5) {
				COLOR = color2;
			} else {
				COLOR = color3;
			}
		} else if (segments == 4) {
			if ((UV.x + UV.y < 0.7) || (UV.x > 0.412 && UV.x < 0.588 && UV.y > 0.55 && UV.y < 0.64)) {
				COLOR = color1;
			} else if ((UV.x - UV.y > 0.3) || (UV.x > 0.412 && UV.x < 0.588 && UV.y > 0.64 && UV.y < 0.725)) {
				COLOR = color4;
			} else if (UV.x < 0.5) {
				COLOR = color2;
			} else {
				COLOR = color3;
			}
		}
	}
}

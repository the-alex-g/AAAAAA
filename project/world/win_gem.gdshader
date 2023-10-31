shader_type canvas_item;

uniform int segments = 1;
uniform vec4 color1 = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 color2 = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 color3 = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 color4 = vec4(0.0, 0.0, 0.0, 0.0);

void fragment() {
	if (COLOR.a > 0.0) {
		if (segments == 1) {

			COLOR = color1;

		} else if (segments == 2) {

			if (UV.x < 0.5) {
				COLOR = color1;
			} else {
				COLOR = color2;
			}
		
		} else if (segments == 3) {
			
			if (UV.y > UV.x / 3.0 && UV.x < 0.5) {
				COLOR = color1;
			} else if (UV.y > -UV.x / 3.0 && UV.x >= 0.5) {
				COLOR = color2;
			} else {
				COLOR = color3;
			}
		
		} else {
			
			if (UV.x < 0.5) {
				if (UV.y < 0.5) {
					COLOR = color1;
				} else {
					COLOR = color2;
				}
			} else {
				if (UV.y < 0.5) {
					COLOR = color3;
				} else {
					COLOR = color4;
				}
			}
		
		}
	}
}

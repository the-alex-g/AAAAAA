shader_type canvas_item;

uniform vec4 color1 = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 color2 = vec4(0.0, 0.0, 0.0, 0.0);


void fragment() {
	if (COLOR == vec4(1.0, 1.0, 1.0, 1.0)) {
		COLOR = color1;
	} else if (COLOR == vec4(1.0, 0.0, 0.0, 1.0)) {
		COLOR = color2;
	}
}
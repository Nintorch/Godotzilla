shader_type canvas_item;

uniform vec4[10] original_palette : source_color;
uniform vec4[10] new_palette : source_color;
uniform bool enable = true;

bool is_equal_approx(float a, float b) {
	const float EPSILON = 0.0001;
	return (a - b) < EPSILON && (a - b) > -EPSILON;
}

bool is_equal_approx_vec(vec4 a, vec4 b) {
	return is_equal_approx(a.r, b.r)
		&& is_equal_approx(a.g, b.g)
		&& is_equal_approx(a.b, b.b)
		&& is_equal_approx(a.a, b.a);
}

void fragment() {
	if (enable) {
		for (int i = 0; i < 10; i++) {
			vec4 color = original_palette[i];
			
			if (is_equal_approx_vec(COLOR, color))
				COLOR = new_palette[i];
		}
	}
}

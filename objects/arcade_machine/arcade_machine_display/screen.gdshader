shader_type canvas_item;

uniform vec4 primary_color : source_color = vec4(vec3(0.0), 1.0);
uniform float static_alpha : hint_range(0.0, 1.0) = 0.0;

float noise(vec2 st){
	return -1. + 2. * fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 static = vec4(vec3(noise(TIME * 0.25 * UV)), 1.0);
	COLOR = mix(primary_color, static, static_alpha);
}

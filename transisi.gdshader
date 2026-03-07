shader_type canvas_item;

uniform float progress : hint_range(0.0,1.0) = 0.0;
uniform float angle = 0.7;
uniform float softness = 0.08;
uniform vec4 color : source_color = vec4(0.0,0.0,0.0,1.0);

void fragment() {

	vec2 uv = UV;

	float wipe = uv.x + uv.y * angle;
	float threshold = progress * (1.0 + angle);

	float edge = smoothstep(threshold - softness, threshold, wipe);

	COLOR = mix(color, vec4(0.0), edge);
}
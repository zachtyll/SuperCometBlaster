shader_type canvas_item;
render_mode unshaded;

uniform sampler2D gradient : hint_black;

void fragment()
{
	vec4 input_colour = texture(TEXTURE, UV);
	float greyscale_value = dot(input_colour.rgb, vec3(0.299, 0.587, 0.114));
	vec3 sampled_colour = texture(gradient, vec2(greyscale_value, 0.0)).rgb;
	COLOR.rgb = sampled_colour;
	COLOR.a = input_colour.a;
}
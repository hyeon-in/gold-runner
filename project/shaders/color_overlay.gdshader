shader_type canvas_item;

instance uniform vec4 overlay_color : source_color = vec4(1.0, 1.0, 1.0, 0);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
    COLOR.rgb = mix(texture_color.rgb, overlay_color.rgb, overlay_color.a);
}
{{GLSL_VERSION}}


{{in}} vec3 middle;
{{in}} vec3 V;

{{out}} vec4 fragment_color;
{{out}} uvec2 fragment_objectid;

float aastep(float threshold, float dist) {
	float afwidth = 0.7 * length(vec2(dFdx(dist), dFdy(dist)));
	return smoothstep(threshold - afwidth, threshold + afwidth, dist);
}

void main() {

	float dist = length(middle - V)*10;
	float alpha = aastep(0.93, dist);
	fragment_color = vec4(1, 0, 0, 1-alpha);
	fragment_objectid = uvec2(0); // not needed yet, but later for point selection and editing
}
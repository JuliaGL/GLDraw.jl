{{GLSL_VERSION}}


{{in}} vec3 middle;
{{in}} vec3 V;

{{out}} vec4 fragment_color;
{{out}} uvec2 fragment_objectid;

uniform float linewidth;

float aastep(float threshold, float dist) {
	float afwidth = 0.9 * length(vec2(dFdx(dist), dFdy(dist)));
	return smoothstep(threshold - afwidth, threshold + afwidth, dist);
}

void main() {

	float dist = length(middle - V) / (linewidth/2);
	float alpha = 1-aastep(0.6, dist);
	fragment_color = vec4(0,0,0, alpha);
	fragment_objectid = uvec2(0); // not needed yet, but later for point selection and editing
}
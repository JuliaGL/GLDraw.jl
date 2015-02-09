
{{GLSL_VERSION}}


{{in}} vec3 middle;
{{in}} vec3 V;

{{out}} vec4 fragment_color;
{{out}} uvec2 fragment_objectid;

uniform float linewidth;


void main() {

	float dist  = length(middle - V) / (linewidth/2);
	float width = fwidth(dist);
	float alpha = 1-smoothstep(0.9, 1.0, dist);
	fragment_color = vec4(0, 0, 0,alpha);
	fragment_objectid = uvec2(0); // not needed yet, but later for point selection and editing
}
{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

uniform float linewidth;
uniform float shadow;
uniform mat4 projection, view;

{{in}} float vertex;

{{out}} vec3 middle;
{{out}} vec3 V;

uniform sampler1D points;


void main(){
    

    int index = gl_InstanceID;

    vec3 A = texelFetch(points, index, 0).rgb;
    vec3 B = texelFetch(points, index+1, 0).rgb;

    vec3 diff       = A - B;
    vec3 normal     = normalize(cross(diff, vec3(1,1,0))); // silly way of getting a normal vector, which later can be used for light calculation too
    vec3 extrude    = normalize(cross(diff, normal));

    float normal_length = linewidth + shadow;
    vec3 scaled_extrude = extrude * normal_length;

    // could be done differently, but this way you emit the points that you need without much memory.
    if (vertex == 1)
    {
        middle  = A;
        V       = A + (scaled_extrude/0.2);
    }
    if (vertex == 2)
    {
        middle  = A;
        V       = A - (scaled_extrude/0.2);
    }
    if (vertex == 3)
    {
        middle  = B;
        V       = B - (scaled_extrude/0.2);
    }
    if (vertex == 4)
    {
        middle  = B;
        V       = B + (scaled_extrude/0.2);
    }
            

    gl_Position = projection * view * vec4(V, 1.0);
}
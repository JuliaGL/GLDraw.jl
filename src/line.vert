{{GLSL_VERSION}}
{{GLSL_EXTENSIONS}}

uniform float linewidth;
uniform float shadow;
uniform mat4 projection, view;

{{in}} float vertex;

{{out}} vec3 middle;
{{out}} vec3 V;

uniform sampler1D points;

int intersect( vec3 P1, vec3 P2, //line 1
               vec3 P3, vec3 P4, //line 2
               out vec3 Pout)       //output point
{ 
    float mua, mub;
    float denom, numera, numerb;
    const float   eps = 0.000000000001;
    Pout.z = 0.0;
    denom  = (P4.y-P3.y) * (P2.x-P1.x) - (P4.x-P3.x) * (P2.y-P1.y);
    numera = (P4.x-P3.x) * (P1.y-P3.y) - (P4.y-P3.y) * (P1.x-P3.x);
    numerb = (P2.x-P1.x) * (P1.y-P3.y) - (P2.y-P1.y) * (P1.x-P3.x);

    if ( (-eps < numera && numera < eps) &&
             (-eps < numerb && numerb < eps) &&
             (-eps < denom  && denom  < eps) ) {
        Pout.x = (P1.x + P2.x) * 0.5;
        Pout.y = (P1.y + P2.y) * 0.5;
        return 2; //meaning the lines coincide
    }

    if (-eps < denom  && denom  < eps) {
        Pout.x = 0;
        Pout.y = 0;
        return 0; //meaning lines are parallel
    }

    mua = numera / denom;
    mub = numerb / denom;
    Pout.x = P1.x + mua * (P2.x - P1.x);
    Pout.y = P1.y + mua * (P2.y - P1.y);
    bool out1 = mua < 0 || mua > 1;
    bool out2 = mub < 0 || mub > 1;

    if ( out1 && out2) {
        return 5; //the intersection lies outside both segments
    } else if ( out1) {
        return 3; //the intersection lies outside segment 1
    } else if ( out2) {
        return 4; //the intersection lies outside segment 2
    } else {
        return 1; //the intersection lies inside both segments
    }
}



void main(){
    

    int index = gl_InstanceID;

    vec3 P0 = texelFetch(points, index, 0).rgb;
    vec3 P1 = texelFetch(points, index+1, 0).rgb;
    vec3 P2 = texelFetch(points, index+2, 0).rgb;
    vec3 P3 = texelFetch(points, index+3, 0).rgb;


    vec3 diff1       = P0 - P1;
    vec3 diff2       = P1 - P2;
    vec3 diff3       = P2 - P3;

    vec3 extrude1    = normalize(cross(diff1, vec3(0,0,1)));
    vec3 extrude2    = normalize(cross(diff2, vec3(0,0,1)));
    vec3 extrude3    = normalize(cross(diff3, vec3(0,0,1)));

    float normal_length = linewidth + shadow;
    vec3 scaled_extrude1 = extrude1 * normal_length;
    vec3 scaled_extrude2 = extrude2 * normal_length;
    vec3 scaled_extrude3 = extrude3 * normal_length;

    vec3 OA1 = P0 + (scaled_extrude1/2);
    vec3 UA1 = P0 - (scaled_extrude1/2);
    vec3 UB1 = P1 - (scaled_extrude1/2);
    vec3 OB1 = P1 + (scaled_extrude1/2);

    vec3 OA2 = P1 + (scaled_extrude2/2);
    vec3 UA2 = P1 - (scaled_extrude2/2);
    vec3 UB2 = P2 - (scaled_extrude2/2);
    vec3 OB2 = P2 + (scaled_extrude2/2);

    vec3 OA3 = P2 + (scaled_extrude3/2);
    vec3 UA3 = P2 - (scaled_extrude3/2);
    vec3 UB3 = P3 - (scaled_extrude3/2);
    vec3 OB3 = P3 + (scaled_extrude3/2);

    // could be done differently, but this way you emit the points that you need without much memory.
    vec3 joint = vec3(0.0);
    if (vertex == 1)
    {
        middle  = P1;
        intersect(UA1, UB1, UA2, UB2, joint);
        V       = joint;
    }
    if (vertex == 2)
    {
        middle  = P1;
        intersect(OA1, OB1, OA2, OB2, joint);
        V       = joint;
    }
    if (vertex == 3)
    {
        middle  = P2;
        intersect(OA2, OB2, OA3, OB3, joint);
        V       = joint;
    }
    if (vertex == 4)
    {
        middle  = P2;
        intersect(UA2, UB2, UA3, UB3, joint);
        V       = joint;
    }

    gl_Position = projection * view * vec4(V, 1.0);
}
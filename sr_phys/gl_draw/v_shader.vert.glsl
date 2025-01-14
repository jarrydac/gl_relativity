#version 430 core

#define MAX_WL_LEN 128

layout (location = 0) in vec4 wl_offset;
layout (location = 1) in int wl_index;

layout (binding=0) uniform sampler2D wls;
layout (binding=1) uniform isampler1D wl_lens;

out vec3 color;

uniform float sr_c;
uniform float time;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

float interval( vec4 a ){
    float t = a.x;
    float x = a.y;
    float y = a.z;
    float z = a.w;
    return sr_c*sr_c*t*t - x*x - y*y - z*z;
}

float[2] intersections( vec4 a, vec4 b ){
    float[2] t = {99,99};

    // Quadratic Quants
    float intv;
    float A;
    float B;
    float C;

    float aa = dot(a,a);
    float ab = dot(a,b);
    float bb = dot(b,b);

    float fact = 1.0/( (b.x-a.x)*(b.x-a.x) );

    A = fact*(aa -2.0*ab + bb) - sr_c*sr_c;
    B = -2.0*fact*(aa*a.x - ab*(a.x+b.x) + bb*a.x);
    C = fact*(aa*b.x*b.x - 2.0*ab*a.x*b.x + bb*a.x*a.x); 

    intv = B*B - 4.0*A*C;

    // Logical non-starter
    if(intv < 0) return t; // Dies silently

    t[0] = ( -B - sqrt( intv ) ) / (2.0*A);
    t[1] = ( -B + sqrt( intv ) ) / (2.0*A); // N.B t2 is larger than t1

    return t;
}

vec4 line( vec4 a, vec4 b, float t ){
    return (1.0/(b.x-a.x)) * ( a*(b.x-t) + b*(t-a.x) ); // This is the line equation.
}

void main(){
    vec4[MAX_WL_LEN] wl;
    int wl_len = texelFetch(wl_lens, wl_index, 0).r;

    for(uint i=0; i<wl_len; i++) wl[i] = texelFetch(wls, ivec2(i, wl_index), 0);

    vec3 scaled_offset = (model*vec4(wl_offset.yzw, 1.0)).xyz;

    struct {
        vec4 a;
        vec4 b;
        float score;
        float t;
    } vertex;

    vec4 s;
    float t;

    vertex.score = 0;

    for(uint i=1; i<wl_len; i++){ // Start at i=1, use i-1;
        // TRANSFORMS
        vec4 a_world = wl[i-1] + vec4(0.0, scaled_offset); // World coords.
        vec4 b_world = wl[i] + vec4(0.0, scaled_offset);

        vec4 a = vec4(a_world.x-time, (view*vec4(a_world.yzw, 1.0)).xyz); // Camera coords
        vec4 b = vec4(b_world.x-time, (view*vec4(b_world.yzw, 1.0)).xyz);

        if( a.x > b.x ){
            // Swap, so we habe the a to b seg
            vec4 tmp;
            tmp = a;
            a = b;
            b = tmp;
        }

        if(!( (interval(a) * interval(b) < 0) && (a.x<0 || b.x<0) )) return;

        // TODO: Apply lorentz.
        float t[2] = intersections(a,b);
        
        float t_0 = 0;

        if(t[0]<0) t_0 = t[0];
        if(t[1]<0) t_0 = t[1];

        if(t_0>a.x && t_0<b.x && t_0!=0){
            float score = 1.0/( abs(interval(a)) + abs(interval(b)) );
            if( score > vertex.score ){
                vertex.a = a;
                vertex.b = b;
                vertex.t = t_0;
                vertex.score = score;
            }
        }
    }

    if(vertex.score != 0){
        s = line( vertex.a, vertex.b, vertex.t );
        t = vertex.t;

        gl_Position = projection * vec4(s.yzw, 1.0);
        color = vec3(0.0f, 0.0f, 0.0f);
    }else{
        gl_Position = vec4(0.0,0.0,0.0,1.0);
        color = vec3(1.0f, 0.0f, 0.0f);
    }
}

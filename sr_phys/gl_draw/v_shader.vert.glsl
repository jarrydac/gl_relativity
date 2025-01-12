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

void main(){
    vec4[MAX_WL_LEN] wl;

    int wl_len = texelFetch(wl_lens, wl_index, 0).r;

    for(uint i=0; i<wl_len; i++) wl[i] = texelFetch(wls, ivec2(i, wl_index), 0);

    vec3 scaled_offset = (model*vec4(wl_offset.yzw, 1.0)).xyz;

    struct {
        vec4 pos;
    } vertex;

    for(uint i=1; i<wl_len; i++){ // Start at i=1, use i-1;
        vec4 a_world = wl[i-1] + vec4(0.0, scaled_offset); // World coords.
        vec4 b_world = wl[i] + vec4(0.0, scaled_offset);

        vec4 a = vec4(a_world.x-time, (view*vec4(a_world.yzw, 1.0)).xyz); // Camera coords
        vec4 b = vec4(b_world.x-time, (view*vec4(b_world.yzw, 1.0)).xyz);

        // TODO: Apply lorentz.

        if( a.x > b.x ){
            // Swap, so we habe the a to b seg
            vec4 tmp;
            tmp = a;
            a = b;
            b = tmp;
        }

        // Quadratic Quants
        float intv;
        float A;
        float B;
        float C;

        vec3 s;
        float t;
        float t1;
        float t2;

        float aa = dot(a,a);
        float ab = dot(a,b);
        float bb = dot(b,b);

        float fact = 1/( (b.x-a.x)*(b.x-a.x) );

        A = fact*(aa -2.0*ab + bb) - sr_c*sr_c;
        B = -2.0*fact*(aa*a.x - ab*(a.x+b.x) + bb*a.x);
        C = fact*(aa*b.x*b.x - 2.0*ab*a.x*b.x + bb*a.x*a.x); 

        intv = B*B - 4.0*A*C;

        t1 = ( -B - sqrt( intv ) ) / (2.0*A);
        t2 = ( -B + sqrt( intv ) ) / (2.0*A); // N.B t2 is larger than t1

        // Logical non-starters
        if(intv < 0) return; // Dies silently
        //if( t1 > 0 && t2 > 0 ) return;
        //if( t1 < 0 && t2 < 0 ) return;

        if( t1<0 ) t=t1;
        if( t2<0 ) t=t2;

        s = (1/(b.x-a.x)) * ( a.yzw*(b.x-t) + b.yzw*(t-a.x) ); // This is the line equation.

        vertex.pos = vec4(0.0, s);
    }

    gl_Position = projection * vec4(vertex.pos.yzw, 1.0);
    color = vec3(0.0f, 0.0f, 0.0f);
}

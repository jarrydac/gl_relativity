#version 430 core

#define MAX_WL_LEN 128

layout (location = 0) in vec4 wl_offset;

layout (binding=0) uniform sampler2D wls;
layout (binding=1) uniform isampler1D wl_lens;

out vec3 color;

out int wl_len;

out vec4 start;
out vec4 end;

out float intv_neg;

uniform uint wl_index;

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

vec4 transform( vec4 a, vec3 scaled_offset ){
    vec4 a_world = a + vec4(0.0, scaled_offset); // World coords.
    return vec4(a_world.x-time, (view*vec4(a_world.yzw, 1.0)).xyz); // Camera coords
}

void main(){
    gl_Position = projection*view*vec4(0.0,0.0,-10.0,1.0);
    color = vec3(0.0,0.0,1.0);

    vec4[MAX_WL_LEN] wl;
    wl_len = texelFetch(wl_lens, int( wl_index), 0).r;
    for(uint i=0; i<wl_len; i++) wl[i] = texelFetch(wls, ivec2(i, wl_index), 0);

    vec4 scaled_offset = vec4(0.0, (model*vec4(wl_offset.yzw,1.0)).xyz);

    intv_neg=0;

    // Infinite Extents
    start = transform(wl[0], scaled_offset.yzw);
    end = transform(wl[wl_len-1], scaled_offset.yzw);
    if( start.x > end.x ){
        vec4 tmp;
        tmp = start;
        start = end;
        end = tmp;
    }

    float t_end = sqrt( dot(end, end) / (sr_c*sr_c) );
    if(t_end > end.x){
        gl_Position = projection*vec4(end.yzw, 1.0); 
        color = vec3(1.0,0.0,0.0);
        return;
    }

    float t_start = -sqrt( dot(start, start) / (sr_c*sr_c) );
    if(t_start < start.x){
        gl_Position = projection*vec4(start.yzw, 1.0); 
        color = vec3(0.0,1.0,0.0);
        return;
    }

    for(int i=1; i<wl_len; i++){
        vec4 a = transform(wl[i-1], scaled_offset.yzw);
        vec4 b = transform(wl[i], scaled_offset.yzw);

        if( a.x > b.x ){
            vec4 tmp;
            tmp = a;
            a = b;
            b = tmp;
        }

        float[2] t = {1.0/0.0,-1.0/0.0};

        // Quadratic Quants
        float intv;
        float A;
        float B;
        float C;

        float aa = dot(a.yzw,a.yzw);
        float ab = dot(a.yzw,b.yzw);
        float bb = dot(b.yzw,b.yzw);

        float fact = 1.0/( (b.x-a.x)*(b.x-a.x) );

        A = fact*(aa -2.0*ab + bb) - sr_c*sr_c;
        B = -2.0*fact*(aa*a.x - ab*(a.x+b.x) + bb*a.x);
        C = fact*(aa*b.x*b.x - 2.0*ab*a.x*b.x + bb*a.x*a.x); 

        intv =  B*B - 4.0*A*C;

        // Logical non-starter
        if(intv > 0){ 
            t[0] = float( ( -B - sqrt( intv ) ) / (2.0*A) );
            t[1] = float( ( -B + sqrt( intv ) ) / (2.0*A) ); // N.B t2 is larger than t1
        }

        if( t[1]>a.x && t[1]<b.x && t[1]<0 ){
            float t = t[1];
            vec4 s = (1.0/(b.x-a.x)) * ( a*(b.x-t) + b*(t-a.x) ); // This is the line equation.
            gl_Position = projection*vec4(s.yzw, 1.0); 
            color = vec3(1.0,1.0,0.0);
            return;
            intv_neg+=intv;
        }
    }
}

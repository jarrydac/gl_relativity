#version 430

#define MAX_WL 63

uniform float time;
uniform float sr_c;

uniform mat4 model;
uniform mat4 view;

uniform uint vbo_offset;

layout(std430, binding=1) readonly buffer event_buffer {
     vec4 events[];
};

layout(std430, binding=3) readonly buffer offset_buffer {
    vec4 offsets[];
};

struct vert {
    vec4 pos;
    float interval;
    float padding[3];
};

layout(std430, binding=2) buffer v_buff {
    vert verts[];
};

layout(local_size_x=1, local_size_y=1, local_size_z=1) in;

float interval( vec4 a ){
    float t = a.x;
    float x = a.y;
    float y = a.z;
    float z = a.w;
    return sr_c*sr_c*t*t - x*x - y*y - z*z;
}

void main(){
    uint i = gl_GlobalInvocationID.x;
    uint j = gl_GlobalInvocationID.y;

    if(i+1 >= events.length()) return;
    if(j >= offsets.length()) return;

    vec3 scaled_offset = (model*vec4(offsets[j].yzw, 1.0)).xyz;

    vec4 a = events[i] + vec4(0.0, scaled_offset); // World coords.
    vec4 b = events[i+1] + vec4(0.0, scaled_offset);

    vec4 a_0 = vec4(a.x, (view*vec4(a.yzw, 1.0)).xyz); // Camera coords
    vec4 b_0 = vec4(b.x, (view*vec4(b.yzw, 1.0)).xyz);
    a_0.x -= time;
    b_0.x -= time;

    if( a_0.x > b_0.x ){
        // Swap, so we habe the a to b seg
        vec4 tmp;

        tmp = a;
        a = b;
        b = tmp;

        tmp = a_0;
        a_0 = b_0;
        b_0 = tmp;
    }

    // a and b are setup here

    // Quadratic Quants
    float intv;
    float A;
    float B;
    float C;

    vec3 s;
    float t;
    float t1;
    float t2;

    float aa = dot(a_0,a_0);
    float ab = dot(a_0,b_0);
    float bb = dot(b_0,b+0);

    float fact = 1/( (b_0.x-a_0.x)*(b_0.x-a_0.x) );

    A = fact*(aa -2.0*ab + bb) - sr_c*sr_c;
    B = -2.0*fact*(aa*a_0.x - ab*(a_0.x+b_0.x) + bb*a_0.x);
    C = fact*(aa*b_0.x*b_0.x - 2.0*ab*a_0.x*b_0.x + bb*a_0.x*a_0.x); 

    intv = B*B - 4.0*A*C;


    t1 = ( -B - sqrt( intv ) ) / (2.0*A);
    t2 = ( -B + sqrt( intv ) ) / (2.0*A); // N.B t2 is larger than t1

    if(intv < 0) return; // Dies silently
    if( t1 > 0 && t2 > 0 ) return;
    if( t1 < 0 && t2 < 0 ) return;

    if( t1<0 ) t=t1;
    if( t2<0 ) t=t2;

    s = (1/(b_0.x-a_0.x)) * ( a.yzw*(b_0.x-t) + b.yzw*(t-a_0.x) ); // This is the line equation.

    float intv_a = interval( a_0 );
    float intv_b = interval( b_0 );

    if( a_0.x < t && t < b_0.x ){
        // Vert is contained
        verts[j+vbo_offset].pos = vec4(t+time, s);
        verts[j+vbo_offset].interval = -1;
    }
}

#version 430

#define MAX_WL 63

uniform float time;
uniform float sr_c;
uniform mat4 model;
uniform mat4 view;

uniform uint wl_lens[2048];

struct wl {
    int count;
    vec4 events[MAX_WL];
};

layout(std430, binding=1) readonly buffer event_buffer {
    wl wls[];
};

struct vert {
    vec4 a;
    vec4 b;
};

layout(std430, binding=2) writeonly buffer v_buff {
    vert verts[];
};

layout(local_size_x=1, local_size_y=64, local_size_z=1) in;

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


    if(i+1 >= wls[j].count) return;
    if(j >= wls.length()) return;

    vec4 a = wls[j].events[i];
    vec4 b = wls[j].events[i+1];

    a.x -= time;
    b.x -= time;

    a.yzw = (view*model*vec4( a.yzw, 1.0)).yzw;
    b.yzw = (view*model*vec4( b.yzw, 1.0)).yzw;

    if( interval( a ) * interval( b ) < 0 && (a.x<0 || b.x<0) ){
        verts[j].a = wls[j].events[i];
        verts[j].b = wls[j].events[i+1];
    }
}

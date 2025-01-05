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
    vec4 a;
    vec4 b;
};

layout(std430, binding=2) writeonly buffer v_buff {
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

    vec4 a = events[i] + vec4(0.0, scaled_offset);
    vec4 b = events[i+1] + vec4(0.0, scaled_offset);

    vec4 a_v = vec4(a.x, (view*vec4(a.yzw, 1.0)).xyz);
    vec4 b_v = vec4(b.x, (view*vec4(b.yzw, 1.0)).xyz);
    a_v.x -= time;
    b_v.x -= time;

    if( interval( a_v ) * interval( b_v ) < 0 && (a_v.x<0 || b_v.x<0) ){
        verts[j+vbo_offset].a = a;
        verts[j+vbo_offset].b = b;
    }
}

#version 330 core
layout (location = 0) in vec4 pos; // Space-time
layout (location = 1) in float intv;

out vec3 color;

uniform float sr_c;
uniform float time;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main(){
    gl_Position = projection * view * model * vec4(pos.yzw, 1.0);
    gl_ClipDistance[0] = -intv;
    color = vec3(0.0f, 0.0f, 0.0f);
}

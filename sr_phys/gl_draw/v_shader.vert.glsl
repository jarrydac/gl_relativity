#version 330 core
layout (location = 0) in vec4 a_st; // Space-time
layout (location = 1) in vec4 b_st;

out vec3 color;

out vec3 s;
out float t;
out float t1;
out float t2;
out float A;
out float B;
out float C;

out float intv;

out vec3 a;
out vec3 b;
out float t_a;
out float t_b;

uniform float sr_c;
uniform float time;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main(){
    if(a_st.x < b_st.x){
        a = (view*model*vec4(a_st.yzw, 1.0)).xyz;
        b = (view*model*vec4(b_st.yzw, 1.0)).xyz;
        t_a = a_st.x - time; // Subtract camera-time is part of camera transform;
        t_b = b_st.x - time;
    } else {
        b = (view*model*vec4(a_st.yzw, 1.0)).xyz;
        a = (view*model*vec4(b_st.yzw, 1.0)).xyz;
        t_a = b_st.x - time;
        t_b = a_st.x - time;
    }

    float aa = dot(a,a);
    float ab = dot(a,b);
    float bb = dot(b,b);

    A = aa - 2.0*ab + bb - sr_c*sr_c;
    B = -2.0*(aa*t_a - ab*(t_a+t_b) + bb*t_b);
    C = aa*t_a*t_a - 2.0*ab*t_a*t_b + bb*t_b*t_b; 

    float intv = B*B - 4.0*A*C;

    if(intv < 0){
        float intv_a = sr_c*sr_c*t_a*t_a - dot(a,a);
        float intv_b = sr_c*sr_c*t_b*t_b - dot(b,b);
        s = a*0.5f + b*0.5f;
        color = vec3(0.5,intv_a,intv_b);
        gl_Position = projection * vec4(s, 1.0);
        return;
    }

    t1 = ( -B - sqrt( intv ) ) / (2.0*A);
    t2 = ( -B + sqrt( intv ) ) / (2.0*A);

    if(t1<(t_b && t1>t_a ) t=t1;
    if(t2<t_b && t2>t_a ) t=t2;

    s = a*(t-t_a) + b*(t_b-t);
    
    gl_Position = projection * vec4(s, 1.0);
    color = vec3(0.0f, 0.0f, 0.0f);
}

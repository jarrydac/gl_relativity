#version 330 core
layout (location = 0) in vec4 a_st; // Space-time
layout (location = 1) in vec4 b_st;

out vec3 color;

uniform float sr_c;
uniform float time;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

/* Intersect a parameterised line from a to b,
   ie. s = (1/(t_b-t_a)**2) * ( a(t_b-t) + b(t-t_a) ) with the 0-interval
   hyperbola ie (ct)**2 = dot(s,s)
   */
void main(){
    vec3 a;
    vec3 b;
    float t_a;
    float t_b;

    float intv;
    float A;
    float B;
    float C;

    vec3 s;
    float t;
    float t1;
    float t2;

    // We will use a->b not b->a
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

    float fact = 1/( (t_b-t_a)*(t_b-t_a) );

    A = fact*(aa -2.0*ab + bb) - sr_c*sr_c;
    B = -2.0*fact*(aa*t_b - ab*(t_a+t_b) + bb*t_a);
    C = fact*(aa*t_b*t_b - 2.0*ab*t_a*t_b + bb*t_a*t_a); 

    intv = B*B - 4.0*A*C;

    float intv_a = sr_c*sr_c*t_a*t_a - dot(a,a);
    float intv_b = sr_c*sr_c*t_b*t_b - dot(b,b);

    if(intv < 0){
        s = a*0.5f + b*0.5f;
        color = vec3(0.5,intv_a,intv_b);
        gl_Position = projection * vec4(s, 1.0);
        return;
    }

    t1 = ( -B - sqrt( intv ) ) / (2.0*A);
    t2 = ( -B + sqrt( intv ) ) / (2.0*A);

    // We want the largest (most recent) negative time.
    if(t1 < t2){
        t = t2<0 ? t2 : t1;    
    }else{
        t = t1<0 ? t1 : t2;
    }

    s = (1/(t_b-t_a)) * ( a*(t_b-t) + b*(t-t_a) ); // This is the line equation.
    
    gl_Position = projection * vec4(s, 1.0);

    color = vec3(0.0f, 0.0f, 0.0f);
}

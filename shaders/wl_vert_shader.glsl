// VERTEX SHADER
/*
    Shader for worldlines.
    We want to take the mesh vertex, and find the correct position with regard to the camera.
*/
#version 430 core

#define MAX_WL_LEN 1024
#define MAX_WL_NUM 1024
#define ITERS 32

// Mesh
layout (location = 0) in vec4 mesh_pos;
layout (location = 1) in vec3 mesh_norm;

// Worldline
uniform uint wl_i;
uniform vec3 final_vel;
uniform vec3 initial_vel;
layout (binding=0) uniform sampler2D wl_tex;
layout (binding=1) uniform isampler1D wl_len_tex;

// Uniforms
uniform float inv_c;    // Inverse speed of light. (hence 0 disables relativistic effect)
uniform float cam_t;    // Current camera time.
uniform mat4 lorentz;   // Lorentz transform matrix.

// Scene transforms.
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

// Out
out vec4 pos_st;
out vec3 norm;
out vec3 vel;

// Space time interval x^2 + y^2 + z^2 - (ct)^2
#define INTERVAL(vec) ( dot((vec).yzw,(vec).yzw) - (1.0/(inv_c*inv_c))*(vec)[0]*(vec)[0] )

// Transform a space-time vector using a mat4.
vec4 ST_TRANSFORM(vec4 vec, mat4 mat){
    vec4 a = ( mat*vec4( vec.yzw, 1.0 ) );
    return vec4(vec.x, a.xyz/a.w);
} 

// Get position offset from model
// ie. model offset with time zero'd.
#define ST_OFFSET ( vec4(0.0, (ST_TRANSFORM(mesh_pos,model)).yzw ) )

// View transform for space-time vector
#define ST_VIEW(vec) ( ST_TRANSFORM( (vec),view ) - vec4( cam_t, vec3(0.0) ) ) 

// Apply lorentz transform and projection
#define ST_PROJ(vec) ( projection * vec4( ( lorentz*( (vec)*vec4(1/inv_c, vec3(1.0)) ) ).yzw, 1.0 ) )

// Fetch pos_st from world-line with interpolation.
vec4 WL(float s){
    // The +0.5 gets the center of the pixel
    vec2 coords = vec2(s, (float(wl_i)+0.5)/float(MAX_WL_NUM));
    vec4 wl_pos = texture( wl_tex, coords );
    return ST_VIEW( wl_pos + ST_OFFSET );
}

// Fetch pos_st from worldline, without interpoltion.
vec4 WL_TEXEL(int s){
    vec4 wl_pos = texelFetch( wl_tex, ivec2(s, wl_i), 0 );
    return ST_VIEW( wl_pos + ST_OFFSET );
} 

// Set out, and world-line
void set(float s, float clip){
    pos_st = WL(s);
    
    // Determine the velocity, using adjacent points
    //vec4 st_a = WL_TEXEL( int( floor(s*float(MAX_WL_LEN)) ) );
    //vec4 st_b = WL_TEXEL( int( ceil(s*float(MAX_WL_LEN)) ) );
    
    // This acts more like a first derivative
    vec4 st_a = WL(s + 0.01/MAX_WL_LEN);
    vec4 st_b = WL(s - 0.01/MAX_WL_LEN);
    vel = (st_b.yzw - st_a.yzw)/(st_b[0] - st_a[0]);
    
    if(inv_c == 0){
        gl_Position = projection * vec4(pos_st.yzw, 1.0);
    }else{
        gl_Position = ST_PROJ( pos_st );
    }
        
    gl_ClipDistance[0] = clip;
}

/*
    We will find the root in view space, since we can simplify the equations if the camera is
    at 0.
    
    We will assume t0 < t1 ... < tn
*/
void main(){
    norm = normalize( mat3(transpose(inverse(model))) * mat3(transpose(inverse(view))) * mesh_norm ); 
    vec3 final_vel_view = normalize( mat3(transpose(inverse(view))) * final_vel ) * length(final_vel); 
    vec3 initial_vel_view = normalize( mat3(transpose(inverse(view))) * initial_vel ) * length(initial_vel); 
    
    if(length(final_vel) == 0) final_vel_view = vec3(0.0);
    if(length(initial_vel) == 0) initial_vel_view = vec3(0.0);

    int wl_l;       // Worldline length
    float a;        // Texture position
    float b;        // Texture position
    
    wl_l = texelFetch(wl_len_tex, int(wl_i), 0).r;

    a = 0.0;
    b = (float(wl_l)-0.5)/float(MAX_WL_LEN);

    // World line is not visible, start point in future.
    vec4 start = WL(a);
    if( start[0] > 0.0 || INTERVAL(start) > 0.0 ){
        float t = start.x;

        float t1 = 0; // positive interval
        float t0 = -1.0/0.0; // negetive interval

        float m;
        for(int i=0; i<ITERS; i++){
            m = (t0+t1)/2.0;
            vec4 mid = vec4(m, start.yzw - (t-m)*initial_vel_view);
            t0 = INTERVAL(mid) > 0.0 ? m : t0;
            t1 = INTERVAL(mid) < 0.0 ? m : t1;
        }

        pos_st = vec4(m, start.yzw - (t-m)*initial_vel_view);
        gl_Position = ST_PROJ(pos_st);
        vel = initial_vel_view;
        return;
    }

    // World line is not visible, end point in past.
    // (Allow an 'infinite' flag?)
    vec4 end = WL(b);
    if( end[0] < 0.0 && INTERVAL(end) < 0.0){
        // TODO: We need to place on the zero interval line!
        float t = end.x;

        float t0 = 0.0; // i.e. camera simultaneous positive interval 
        float t1 = end.x; // negetive interval
        
        float m;
        for(int i=0; i<ITERS; i++){
            m = (t0+t1)/2.0;
            vec4 mid = vec4(m, end.yzw + (m-t)*final_vel_view);
            t0 = INTERVAL(mid) > 0.0 ? m : t0;
            t1 = INTERVAL(mid) < 0.0 ? m : t1;
        }
        

        pos_st = vec4(m, end.yzw + (m-t)*final_vel_view);
        gl_Position = ST_PROJ(pos_st);
        vel = initial_vel_view;

        return;
    }

    // Find t=0 by bisection
    for(int i=0; i<ITERS; i++){
        float m = (a+b)/2.0;
        vec4 mid = WL( m );
        a = mid[0] < 0.0 ? m : a;
        b = mid[0] > 0.0 ? m : b;
    }    
    
    if(inv_c == 0){
        set(b,0.0);
        return;
    }

    // Find INTERVAL = 0 by bisection.
    a = 0.0;
    for(int i=0; i<ITERS; i++){
        float m = (a+b)/2.0;
        vec4 mid = WL( m );
        a = INTERVAL(mid) < 0.0 ? m : a;
        b = INTERVAL(mid) > 0.0 ? m : b;
    }    
    
    set( b, 0.0);
}

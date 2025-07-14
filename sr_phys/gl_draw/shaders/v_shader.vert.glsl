#version 430 core

#define MAX_WL_LEN 128

// Mesh properties
layout (location = 0) in vec4 mesh_pos;
layout (location = 1) in vec3 mesh_norm;

// Anchor wl properties
uniform uint wl_index;
layout (binding=0) uniform sampler2D wls;
layout (binding=1) uniform isampler1D wl_lens;

out vec3 color;
out int wl_len;

uniform float sr_c;
uniform float time;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform mat4 lorentz;

out vec4 pos_st;
out vec3 norm;
out vec3 vel;
// Utility functions

// Spacetime interval
float interval( vec4 st ){
    float t = st.x;
    return sr_c*sr_c*t*t - dot(st.yzw, st.yzw);
}

// Apply homogenous transform to position of a space-time point
vec4 transform_st( mat4 transform, vec4 st ){
    return vec4(st.x, (transform*vec4(st.yzw, 1.0)).xyz ); 
}

// Transforms
vec4 view_transform( vec4 anchor_point, vec4 mesh_point ){
    vec4 world_st = anchor_point + mesh_point;
    vec4 view_st = transform_st(view, world_st) - vec4(time, vec3(0.0));
    return view_st;
}

// Combined lorentz and projection transforms 
vec4 projection_transform( vec4 st ){
    return projection*vec4( ( lorentz*(vec4(sr_c,1.0,1.0,1.0)*st) ).yzw , 1.0);
}

// The lightcone intersects a given position s once for t<0; 
float s_intersection( vec3 s ){
    return -sqrt( dot(s,s) / (sr_c*sr_c) );
}

// We always want the
float ab_intersection( vec4 a_st, vec4 b_st ){
    float[2] t = {1.0/0.0,-1.0/0.0}; // Use +INF and -INF as good defaults

    // Quadratic Quants
    float intv;
    float A;
    float B;
    float C;

    // Had to repeat this analysis, but it appears correct now
    // use s = ( 1/(t_b-t_a) )*( a*(t_b-t) + b*(t-t_a) )
    // and (c*t)**2 = dot(s,s);
    // N.B factor out t first!
    float fact = 1.0/( (b_st.x-a_st.x)*(b_st.x-a_st.x) );
    A = fact*dot(b_st.yzw-a_st.yzw, b_st.yzw-a_st.yzw) - sr_c*sr_c;
    B = fact*2.0*dot(a_st.yzw*b_st.x - b_st.yzw*a_st.x, b_st.yzw-a_st.yzw);
    C = fact*dot(a_st.yzw*b_st.x-b_st.yzw*a_st.x,a_st.yzw*b_st.x-b_st.yzw*a_st.x);

    intv =  B*B - 4.0*A*C;

    // We need interval to be positive
    if(intv > 0){ 
        // https://math.stackexchange.com/questions/311382/solving-a-quadratic-equation-with-precision-when-using-floating-point-variables
        t[0] = float( ( -B - sqrt( intv ) ) / (2.0*A) );
        t[1] = float( ( -B + sqrt( intv ) ) / (2.0*A) );
    }

    // The larger t is the sensical one
    return t[1];
}

// Interpolate vec4s based on t (in pos .x)
// NOTE: could interpolate e.g. normals or tex coords in future
vec4 ab_interpolate( vec4 a, vec4 b, float t){
    return (1.0/(b.x-a.x)) * ( a*(b.x-t) + b*(t-a.x) ); // This is the line equation.
}


void main(){
    norm = mat3(transpose(inverse(model))) * mesh_norm; 

    gl_Position = projection*view*vec4(0.0,0.0,-10.0,1.0);
    color = vec3(0.0,0.0,1.0);
    vel = vec3(0.0,0.0,0.0);

    wl_len = texelFetch(wl_lens, int(wl_index), 0).r;

    // Vertex position relative to the anchor point, with model matrix applied
    vec4 mesh_offset_st = transform_st(model, mesh_pos);
    mesh_offset_st.x = 0;

    // Worldline terminals
    // We test if the intersections are after the last event, or before the first event,
    // and terminate early if so
    vec4 start_st = view_transform( texelFetch(wls, ivec2(0, wl_index),0 ), mesh_offset_st);
    vec4 end_st = view_transform( texelFetch(wls, ivec2(wl_len-1,wl_index),0), mesh_offset_st);

    // TODO: Decide if we'd like to allow for monotonically decreasing worldline times
    // For now, allow with a swap
    if( start_st.x > end_st.x ){
        vec4 tmp;
        tmp = start_st;
        start_st = end_st;
        end_st = tmp;
    }

    float end_s_intersection_t = s_intersection( end_st.yzw );  // Intersection time t for end s
    if(end_s_intersection_t > end_st.x){
        gl_Position = projection_transform( vec4(end_s_intersection_t, end_st.yzw) );
        pos_st =  vec4(end_s_intersection_t, end_st.yzw);
        color = vec3(1.0,0.0,0.0);
        return;
    }

    float start_s_intersection_t = s_intersection( start_st.yzw );  // Intersection time t for start s
    if(start_s_intersection_t < start_st.x){
        // TODO: For now we are displaying this point in a different color,
        // but it makes sense to clip the vertex by time-intersection_t
        gl_Position = projection_transform( vec4(start_s_intersection_t, start_st.yzw) );
        pos_st =  vec4(start_s_intersection_t, start_st.yzw);
        color = vec3(0.0,1.0,0.0);
        return;
    }

    for(int i=1; i<wl_len; i++){
        vec4 a_st = view_transform( texelFetch(wls, ivec2(i-1,wl_index),0), mesh_offset_st);
        vec4 b_st = view_transform( texelFetch(wls, ivec2(i,wl_index),0), mesh_offset_st);

        // TODO: Ditto, monotonic decreasing?
        if( a_st.x > b_st.x ){
            vec4 tmp;
            tmp = a_st;
            a_st = b_st;
            b_st = tmp;
        }

        float intersection_t = ab_intersection( a_st, b_st );

        // We need the intersection to actually lie between the a and b,
        // We know this happens twice, once for t<0 and for t>0 if our worldlines are 
        // sensible.
        if( intersection_t>a_st.x && intersection_t<b_st.x && intersection_t<0 ){
            pos_st = ab_interpolate( a_st, b_st, intersection_t );
            gl_Position = projection_transform( pos_st );
            
            // Basic velocity formula
            vel = (b_st.yzw - a_st.yzw) / (b_st.x - a_st.x);
            

            color = vec3(1.0,1.0,0.0);
            return;
        }
    }
}

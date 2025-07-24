#version 430 core
#define MAX_PEAKS 10
#define MAX_LIGHTS 10

in vec3 color;
in vec3 vel;
in vec4 pos_st;
in vec3 norm;

out vec4 FragColor;

uniform vec3 cam_vel;
uniform mat4 lorentz; 
uniform mat4 view;
uniform mat4 model;
// Given in (intensity, wavelength)
uniform vec2 wavelength;
uniform float sr_c;

layout (binding=2) uniform sampler2D continuous_spectra;
layout (binding=3) uniform sampler1D cie_data;

struct light {
    vec3 pos;
    // Continuous Spectrum
    int cont_id;
    // Discrete Spectrum
    vec2 peaks[MAX_PEAKS];
    int peaks_len;
};

uniform light lights[MAX_LIGHTS];
uniform int lights_len;

mat3 T_rgb_xyz;
mat3 T_xyz_rgb;

float gamma(vec3 vel){
    return pow( ( 1 - ( length(vel)*length(vel) ) / (sr_c*sr_c) ), -0.5);
}

float shift_factor(float gamma, float theta){
    return gamma*( 1+sqrt(1-1/(gamma*gamma))*cos(theta) );
}

float angle(vec3 a, vec3 b){
    float norm_dot = dot( normalize(a), normalize(b) );
    float angle = acos( norm_dot );
    return sign(norm_dot) * angle;
}


// Piecewise Gaussian, which is asymmetric about mu, with variance of tau1 on
// left and tau2 on the right.
float piecewise_gaussian(float x, float mu, float tau1, float tau2){
    float center = x-mu;
    float left = exp(-0.5 * (tau1*tau1) * center*center);
    float right = exp(-0.5 * (tau2*tau2) * center*center);
    return step(x,mu) * right + (1-step(x,mu)) * left;
}

vec3 rel_rgb(float intensity, float wavelength){
    // Position addition formula?
    vec3 rel_vel = vel - cam_vel;

    float gamma = gamma( rel_vel );
    float theta = angle( rel_vel, pos_st.yzw );
    float factor = shift_factor(gamma, theta);
    
    vec2 color_v = vec2(intensity, wavelength) * vec2(1.0, factor);
    
    float X_data =  +1.056*piecewise_gaussian( color_v[1], 599.8, 0.0264, 0.0323)
                    +0.362*piecewise_gaussian( color_v[1], 442.0, 0.0624, 0.0374)
                    -0.065*piecewise_gaussian( color_v[1], 501.1, 0.0490, 0.382);

    float Y_data =  +0.821*piecewise_gaussian( color_v[1], 568.8, 0.0212, 0.0247)
                    +0.286*piecewise_gaussian( color_v[1], 530.9, 0.0613, 0.0322);

    float Z_data =  +1.217*piecewise_gaussian( color_v[1], 437.0, 0.0845, 0.0278)
                    +0.681*piecewise_gaussian( color_v[1], 459.0, 0.0385, 0.0725);

    vec3 rgb = T_xyz_rgb * vec3(X_data, Y_data, Z_data) * color_v[0];
    
    float r = max(rgb.r, 0.0);
    float g = max(rgb.g, 0.0);
    float b = max(rgb.b, 0.0);
    
    return vec3(r,g,b);
}

void main(){
    T_rgb_xyz[0] = vec3(0.49000, 0.17697, 0.00000);
    T_rgb_xyz[1] = vec3(0.31000, 0.81240, 0.01000);
    T_rgb_xyz[2] = vec3(0.20000, 0.01063, 0.99000);
    T_xyz_rgb = inverse(T_rgb_xyz);
    
    vec3 transformed_norm = mat3(transpose(inverse(model))) * mat3(transpose(inverse(view))) * norm;

    vec3 rel_vel = vel - cam_vel;
    float cam_gamma = gamma( rel_vel );
    float cam_theta = angle( rel_vel, pos_st.yzw );
    float camera_shift_factor = shift_factor(cam_gamma, cam_theta);

    float ambient_wavelength = 600.0;
    float ambient_intensity = 0.0;

    float specular_reflection = 1.0;   
    float ambient_reflection = 1.0;   
    float diffuse_reflection = 0.8;   

        // Ambient lighting
    vec3 total_rgb = ambient_reflection * rel_rgb(ambient_intensity, ambient_wavelength);

    for(int i=0; i<lights_len; i++){
        light light = lights[i];
        // We are going to start with one monochrome light.
        vec4 light_pos4 = view * vec4(light.pos,1.0);
        vec3 light_pos = light_pos4.xyz / light_pos4.w;

        float light_gamma = gamma( -vel );
        float light_theta = angle( -vel, light_pos - pos_st.yzw );
        float light_shift = shift_factor( light_gamma, light_theta );

        vec3 viewer_dir = normalize( -pos_st.yzw );
        vec3 reflect_dir = reflect( normalize( pos_st.yzw - light_pos ), transformed_norm );
        int speculence = 2;
        float spec = pow(max(dot(viewer_dir, reflect_dir), 0.0), speculence);
        //
        // Discrete Lighting
        //
        for(int j=0; j<light.peaks_len; j++){
            float light_wavelength = light.peaks[j].x;
            float light_intensity = light.peaks[j].y;

            // Diffuse lighting
            total_rgb += 
                diffuse_reflection * 
                max(dot( normalize( light_pos-pos_st.yzw ), transformed_norm ),0.0) * 
                rel_rgb( light_intensity, light_wavelength*light_shift );

            // Specular Lighting
            total_rgb += specular_reflection * spec 
               * rel_rgb( light_intensity, light_wavelength*light_shift );
            
        }

        //
        // Continuous Lighting
        //
        if(light.cont_id != -1){
            vec3 xyz = vec3(0.0);
            for(int i=360; i<830; i++){
                // We'll work from the observer frame backward to the light source
                //float emmision = texture(continuous_spectra, vec2( ( ( (float(i)/camera_shift_factor*light_shift)-300.0)/(5.0) ), float(light.cont_id) ) / vec2(100.0,10.0) ).r;
                float emmision = texture(continuous_spectra, vec2( -3*log( float(i)*1e-9/(camera_shift_factor*light_shift) ), float(light.cont_id) ) / vec2(100.0,10.0) ).r;
                
                // Diffuse
                xyz += diffuse_reflection *
                    max(dot( normalize( light_pos-pos_st.yzw ), norm ),0.0) * 
                    texture( cie_data, float( i-360 )/470.0 ).xyz *
                    diffuse_reflection * // eval diffuse reflection at cam-shifted wl.
                    emmision;
                // Spectral
                xyz += specular_reflection * 
                    spec * 
                    texture(cie_data, float( i-360 )/470.0 ).xyz *
                    specular_reflection *
                    emmision;
            }

            total_rgb += T_xyz_rgb * xyz;
        }
        
        
        float r = clamp(total_rgb.r, 0.0, 1.0);
        float g = clamp(total_rgb.g, 0.0, 1.0);
        float b = clamp(total_rgb.b, 0.0, 1.0);
        
        FragColor = vec4( vec3(r,g,b)*vec3(1.0,1.0,1.0), 1.0f);
    }
}

#version 430 core

#define MAX_PEAKS 10
#define MAX_LIGHTS 10

#define CIE_START 360
#define CIE_END 890

#define SPECTRUM_LENGTH 100

in vec4 pos_st;
in vec3 norm;
in vec3 vel;

out vec4 FragColor;

uniform vec3 cam_vel;
uniform mat4 lorentz; 
uniform mat4 view;
uniform mat4 model;
uniform float inv_c;

layout (binding=2) uniform sampler2D continuous_spectra;
layout (binding=3) uniform sampler1D cie_data;

struct light {
    vec3 pos;
    // Continuous Spectrum
    int cont_id;
    // Discrete Spectrum (nanometers)
    vec2 peaks[MAX_PEAKS];
    int peaks_len;
};

uniform light lights[MAX_LIGHTS];
uniform int lights_len;

mat3 T_rgb_xyz;
mat3 T_xyz_rgb;

float angle(vec3 a, vec3 b){
    float norm_dot = dot( normalize(a), normalize(b) );
    float angle = acos( norm_dot );
    return sign(norm_dot) * angle;
}

// N.B. Wavelength in meters
float sample_light_spectrum(int cont_id, float wavelength){
    vec2 scale_factor = vec2(SPECTRUM_LENGTH,MAX_LIGHTS);
    // The first coordinate is an inverse transform of the transform used when the spectrum is stored,
    // in order to allow sampling a wider range of the spectrum.
    vec2 tex_coords = vec2( -3*log( wavelength ), float(cont_id) ) / scale_factor;
    return texture(continuous_spectra, tex_coords).r;
}

// N.B. Wavelength in meters
vec3 sample_cie_data(float wavelength){
    float scale_factor = CIE_END-CIE_START;
    float tex_coord = (wavelength*1e9 - CIE_START)/scale_factor;    
    return texture(cie_data, tex_coord).xyz;
}

// https://en.wikipedia.org/wiki/Velocity-addition_formula#General_configuration
vec3 velocity_addition(vec3 u, vec3 v){
    vec3 u_para = dot(u, normalize(v)) * normalize(v); 
    vec3 u_perp = u-u_para;
    
    float factor = 1 + dot(u,v)*inv_c*inv_c;
    
    vec3 u_prime_para = (u_para + v) / factor;    
    vec3 u_prime_perp = sqrt( 1-dot(v,v)*inv_c*inv_c ) * u_perp / factor;

    return u_prime_para+u_prime_perp;
}

void main(){
    //FragColor = vec4(1.0);
    //return;
    
    vec3 cam_vel_view = mat3(transpose(inverse(view))) * cam_vel; 
    vec3 vel_view = mat3(transpose(inverse(view))) * vel; 


    T_rgb_xyz[0] = vec3(0.49000, 0.17697, 0.00000);
    T_rgb_xyz[1] = vec3(0.31000, 0.81240, 0.01000);
    T_rgb_xyz[2] = vec3(0.20000, 0.01063, 0.99000);
    T_xyz_rgb = inverse(T_rgb_xyz);
    
    vec3 transformed_norm = norm;

    float ambient_wavelength = 600.0;
    float ambient_intensity = 0.0;

    float specular_reflection = 1.0;   
    float ambient_reflection = 1.0;   
    float diffuse_reflection = 0.8;   

    // Ambient lighting
    vec3 total_rgb = ambient_reflection * T_rgb_xyz * sample_cie_data(ambient_wavelength);

    for(int i=0; i<lights_len; i++){
        light light = lights[i];
        
        //
        // Calculate the factors between the observer, the fragment and the light source
        //
        vec4 light_pos4 = view * vec4(light.pos,1.0);

        // lab position of the fragment
        vec3 pos_fragment_lab = pos_st.yzw;
        // cam-frame position of the fragment
        vec3 pos_fragment_cam = (lorentz * pos_st).yzw;
        // lab position of the light
        vec3 pos_light_lab = light_pos4.xyz / light_pos4.w;
        // cam position of the light
        // TODO: THIS APPROXIMATION IS WRONG?
        vec3 pos_light_cam = (lorentz * vec4(0.0,pos_light_lab)).yzw;

        // velocity of the fragment in the lab frame
        vec3 vel_fragment_lab = vel_view;
        // velocity of the fragment in the camera frame
        vec3 vel_fragment_cam = velocity_addition(vel_view, -cam_vel_view);
            
        // Angle of the line between emitter and fragment, and fragment velocity
        float cos_theta = dot( normalize(vel_fragment_lab), normalize(pos_fragment_lab-pos_light_lab) );
        
        // Angle between the observer and the fragment velocity, in the camera frame
        float cos_theta_prime = dot( normalize(vel_fragment_cam), normalize(pos_fragment_cam) );

        float light_fragment_shift = 1 / ( 1 - length(vel_fragment_lab)*cos_theta*inv_c );
        float fragment_observer_shift = ( 1 + length(vel_fragment_cam)*cos_theta_prime*inv_c );
        
        if( length(vel_fragment_lab) == 0.0 ){
            light_fragment_shift = 1;
        }
        
        if( length(cam_vel_view) == 0.0 ){
            fragment_observer_shift = 1;
        }
        
        float light_observer_shift = light_fragment_shift * fragment_observer_shift;
        float observer_light_shift = 1/light_observer_shift;    

        vec3 viewer_dir = normalize( -pos_fragment_cam );
        vec3 reflect_dir = reflect( normalize( pos_fragment_cam - pos_light_cam ), transformed_norm );
        int speculence = 2;
        float spec = pow(max(dot(viewer_dir, reflect_dir), 0.0), speculence);
        
        //
        // Discrete Lighting
        //
        for(int j=0; j<light.peaks_len; j++){
            // Work forward from the emission wavelength (in meters) to the observed wavelength
            float light_lambda = light.peaks[j].x * 1e-9;
            float observer_lambda = light_lambda * light_observer_shift;

            float emission_intensity = light.peaks[j].y;
            
            // X,Y,Z sensitivities to the given wavelength
            vec3 cie_sensitivities = sample_cie_data(observer_lambda);


            // Diffuse lighting
            total_rgb += 
                diffuse_reflection * 
                max(dot( normalize( pos_light_cam - pos_fragment_cam ), transformed_norm ),0.0) * 
                emission_intensity * 
                T_xyz_rgb * cie_sensitivities;

            // Specular Lighting
            total_rgb += specular_reflection * 
                spec * 
                emission_intensity * 
                T_xyz_rgb * cie_sensitivities;
        }

        //
        // Continuous Lighting
        //
        if(light.cont_id != -1){
            vec3 xyz = vec3(0.0);

            for(int i=CIE_START; i<CIE_END; i++){
                // Step through observer wavelengths in CIE data (in meters)
                // We'll work from the observer frame backward to the light source
                float observer_lambda = float(i)*1e-9;
                float light_lambda = observer_lambda * observer_light_shift;

                // Intensity of the observer wavelength at the light source
                float emission_intensity = sample_light_spectrum(light.cont_id, light_lambda);
                
                // Diffuse
                xyz += diffuse_reflection *
                    max(dot( normalize(pos_light_lab - pos_fragment_cam ), norm ),0.0) * 
                    sample_cie_data(observer_lambda) *
                    diffuse_reflection * // TODO: eval diffuse reflection at cam-shifted wl.
                    emission_intensity;
                // Spectral
                xyz += specular_reflection * 
                    spec * 
                    sample_cie_data(observer_lambda) *
                    specular_reflection *
                    emission_intensity;
            }

            total_rgb += T_xyz_rgb * xyz;
        }
        
        float r = clamp(total_rgb.r, 0.0, 1.0);
        float g = clamp(total_rgb.g, 0.0, 1.0);
        float b = clamp(total_rgb.b, 0.0, 1.0);
        
        FragColor = vec4(r,g,b,1.0);
    }
}

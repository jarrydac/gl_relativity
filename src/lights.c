#include "../include/lights.h"
#include <stdio.h>

#define MAX_LIGHTS 10

#define SPEC_UNIT GL_TEXTURE0+2
#define CIE_UNIT GL_TEXTURE0+3

GLuint spec_tex;
GLuint cie_tex;
int cont_spec_len;

sr_light* lights[MAX_LIGHTS];
int lights_len;

int sr_lights_init(vec3 cie_data[471]){
    lights_len = 0;

    glGenTextures(1, &spec_tex);
    glGenTextures(1, &cie_tex);
    cont_spec_len = 0;

    glActiveTexture(SPEC_UNIT);
    glBindTexture(GL_TEXTURE_2D, spec_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // Why do i need to set these on my laptop??
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Why do i need to set these on my laptop??
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    float border[4] = {0.0f, 0.0f, 0.0f, 0.0f};
    glTexParameterfv(GL_TEXTURE_1D,GL_TEXTURE_BORDER_COLOR, border);
    glTexImage2D(GL_TEXTURE_2D, 
            0, GL_R32F, 
            MAX_SAMPLE_MAG, MAX_LIGHTS, 
            0, GL_RED, GL_FLOAT, NULL
            );
    
    // Load CIE Data
    glActiveTexture(CIE_UNIT);
    glBindTexture(GL_TEXTURE_1D, cie_tex);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // Why do i need to set these on my laptop??
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Why do i need to set these on my laptop??
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAX_LEVEL, 0);
    glTexParameteri(GL_TEXTURE_1D,GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexImage1D(GL_TEXTURE_1D, 
            0, GL_RGB32F, 
            471, 
            0, GL_RGB, GL_FLOAT, 
            cie_data
            );

    return 0;
}

void sr_lights_close(){
   glDeleteTextures(1,&spec_tex); 
   glDeleteTextures(1, &cie_tex);
}

int sr_lights_discrete_spectrum_init(
    sr_light_discrete_spectrum* spec,
    vec2* peaks,
    int len
){
    if (len>MAX_LIGHTS) return 1;

    for(int i=0; i<len; i++){
       glm_vec3_copy( peaks[i], spec->peaks[i] );
    }
    spec->length = len;    
    printf("%d",len);
    return 0;
}

// Discrete Spectrum
void sr_lights_discrete_spectrum_delete(sr_light_discrete_spectrum* spec){ }


int sr_light_init(
    sr_light* light, 
    vec3 pos,
    sr_light_continuous_spectrum* cont_spectrum, 
    sr_light_discrete_spectrum* disc_spectrum 
){
    glm_vec3_copy( pos, light->pos );
    
    light->cont_spectrum = cont_spectrum;
    light->disc_spectrum = disc_spectrum;
    
    return 0;
}

// Continuous Spectrum
int sr_lights_continuous_spectrum_init(
    sr_light_continuous_spectrum* spec, 
    float samples[MAX_SAMPLE_MAG]
){
    if(cont_spec_len > MAX_LIGHTS) return 1;
    spec->id = cont_spec_len++;

    glBindTexture(GL_TEXTURE_2D,spec_tex);
    glTexSubImage2D(
        GL_TEXTURE_2D,
        0,
        0,
        spec->id,
        MAX_SAMPLE_MAG,
        1,
        GL_RED,
        GL_FLOAT,
        samples
    );
    
    return 0;
}

void sr_lights_continuous_spectrum_delete(sr_light_continuous_spectrum* spec){ }

void sr_light_delete(sr_light* light){}

int sr_lights_add(sr_light* light){
    if(lights_len >= MAX_LIGHTS){
        return 1;
    }
    
    lights[lights_len] = light;
    lights_len++;
    
    return 0;
}

void sr_lights_close(void);


void sr_lights_load_uniforms(GLuint program){
    for(int i=0; i<lights_len; i++){
        char pos_loc_str[100];
        char peak_len_loc_str[100];
        char lights_len_loc_str[100];
        char cont_id_loc_str[100];
        sprintf(pos_loc_str, "lights[%d].pos", i);
        sprintf(peak_len_loc_str, "lights[%d].peaks_len", i);
        sprintf(cont_id_loc_str, "lights[%d].cont_id", i);
        sprintf(lights_len_loc_str, "lights_len");
        
        glUniform1i( glGetUniformLocation(program, lights_len_loc_str), lights_len);

        glUniform3fv( glGetUniformLocation(program, pos_loc_str), 1, (float*) lights[i]->pos);

        if(lights[i]->cont_spectrum){
            glUniform1i( glGetUniformLocation(program, cont_id_loc_str), lights[i]->cont_spectrum->id);
        }else{
            glUniform1i( glGetUniformLocation(program, cont_id_loc_str), -1);
        }
        
        if(lights[i]->disc_spectrum){
            glUniform1i( glGetUniformLocation(program, peak_len_loc_str), lights[i]->disc_spectrum->length);
            for(uint j=0; j<lights[i]->disc_spectrum->length; j++){
                char peak_loc_str[100];
                sprintf(peak_loc_str, "lights[%d].peaks[%d]", i, j);
                glUniform2fv( glGetUniformLocation(program, peak_loc_str), 1, (float*) lights[i]->disc_spectrum->peaks[j]);
            }
        }else{
            glUniform1i( glGetUniformLocation(program, peak_len_loc_str), 0);
        }
    }
}

void sr_lights_bind_textures(){
    glActiveTexture(SPEC_UNIT);
    glBindTexture(GL_TEXTURE_2D, spec_tex);
    glActiveTexture(CIE_UNIT);
    glBindTexture(GL_TEXTURE_1D, cie_tex);
}
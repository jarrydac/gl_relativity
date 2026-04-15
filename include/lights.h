#ifndef SR_DRAW_LIGHT
#define SR_DRAW_LIGHT

#define MAX_DISCRETE_LEN 10
#define MAX_SAMPLE_MAG 100


#include "../lib/include/glad/gl.h"
#include "../lib/include/cglm/cglm.h"

typedef struct {
    unsigned int id;
} sr_light_continuous_spectrum;

typedef struct {
    vec2 peaks[MAX_DISCRETE_LEN];
    unsigned int length;
} sr_light_discrete_spectrum;

typedef struct {
    vec3 pos;
    sr_light_continuous_spectrum* cont_spectrum;
    sr_light_discrete_spectrum* disc_spectrum;
} sr_light;


int sr_lights_init(vec3 cie_data[471]);
int sr_lights_add(sr_light* light);
void sr_lights_close(void);

int sr_lights_continuous_spectrum_init(
    sr_light_continuous_spectrum* spec, 
    float samples[MAX_SAMPLE_MAG]
);
void sr_lights_continuous_spectrum_delete(sr_light_continuous_spectrum* spec);

int sr_lights_discrete_spectrum_init(
    sr_light_discrete_spectrum* spec,
    vec2* peaks,
    int len
);
void sr_lights_discrete_spectrum_delete(sr_light_discrete_spectrum* spec);

int sr_light_init(
    sr_light* light, 
    vec3 pos,
    sr_light_continuous_spectrum* cont_spectrum, 
    sr_light_discrete_spectrum* disc_spectrum 
);
void sr_light_delete(sr_light* light);

void sr_lights_load_uniforms(GLuint program);
void sr_lights_bind_textures();

#endif
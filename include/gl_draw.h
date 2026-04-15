#include "../lib/include/glad/gl.h"
#include "../lib/include/cglm/cglm.h"

#include "shaders.h"
#include "camera.h"
#include "objects.h"
#include "mesh.h"
#include "lights.h"

// Init functions.
int sr_draw_init( 
    char* v_shader_str, 
    char* f_shader_str, 
    char* c_shader_str,
    vec3 cie_data[471]
);
void sr_close(void);

void sr_clear(float r, float g, float b);

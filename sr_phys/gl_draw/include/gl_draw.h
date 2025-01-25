#include "../lib/include/glad/gl.h"
#include "../lib/include/cglm/cglm.h"

#include "shaders.h"
#include "camera.h"
#include "objects.h"
#include "mesh.h"

// Init functions.
int sr_draw_init( char* v_shader_str, char* f_shader_str, char* c_shader_str );
void sr_close(void);

void sr_clear(void);

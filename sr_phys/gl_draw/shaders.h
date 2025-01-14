#ifndef SR_DRAW_SHADERS
#define SR_DRAW_SHADERS

#include "include/glad/gl.h"

#include "include/cglm/cglm.h"

/**
 *  Shader loading module.
 */
int sr_shaders_init( char* vertex_shader, char* fragment_shader );

// object.h shader program
void sr_use_obj_program(mat4 model);

#endif

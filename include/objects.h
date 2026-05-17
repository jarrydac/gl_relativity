/* Drawing Functions */
#ifndef SR_DRAW_OBJECTS
#define SR_DRAW_OBJECTS

#include "../lib/include/cglm/cglm.h"

#include "mesh.h"

#define MAX_WL_LEN 1024
#define MAX_WL_NUM 1024

typedef struct {
    vec4 events[MAX_WL_LEN];
    vec3 initial_vel;
    vec3 final_vel;
    int length;
} sr_obj_wl;

typedef struct {
    unsigned int anchor_wl;
    vec3 wl_initial_vel;
    vec3 wl_final_vel;
    sr_mesh* mesh;
    mat4 model;
    vec2 color;
} sr_object;

void sr_objects_init(void);     // init
void sr_objects_render(void);   // call draw functions
void sr_objects_close(void);    // close

int sr_object_init( sr_object* object, sr_obj_wl* wl, sr_mesh* mesh, mat4 model, vec2 color );
void sr_object_delete( sr_object* );

void sr_object_update_wl( sr_object* object, sr_obj_wl* wl );           // Overwrite wl in the wls texture, and length in the lengths texture
int sr_object_update_mesh( sr_object* object, sr_mesh* mesh );     // Generate new vbo and ebo
void sr_object_update_model( sr_object* object, mat4 model );           // Just update in datatype 

void sr_object_draw( sr_object* object );                               // Draw object this frame
                                                                        
#endif

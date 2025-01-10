/* Drawing Functions */
#ifndef SR_DRAW_OBJECTS
#define SR_DRAW_OBJECTS

#include "include/cglm/cglm.h"

#define MAX_WL_LEN 128
#define MAX_WL_NUM 1024

typedef struct {
    unsigned int wl_index;
    vec4 offset;
} sr_obj_render_vert;

typedef struct {
    vec4 events[MAX_WL_LEN];
    int length;
} sr_obj_wl;

typedef struct {
    int* indicies;
    int indicies_len;
    vec4* offsets;
    int offsets_len;
} sr_obj_mesh;

typedef struct {
    unsigned int anchor_wl;
    unsigned int anchol_wl_len;
    unsigned int vbo_id;
    unsigned int ebo_id;
    unsigned int vao_id;
    unsigned int elements_count;
    mat4 model;
} sr_object;

void sr_objects_init(void);     // init
void sr_objects_render(void);   // call draw functions
void sr_objects_close(void);    // close

int sr_object_init( sr_object* object, sr_obj_wl* wl, sr_obj_mesh* mesh, mat4 model );
void sr_object_delete( sr_object* );

void sr_object_update_wl( sr_object* object, sr_obj_wl* wl );           // Overwrite wl in the wls texture, and length in the lengths texture
int sr_object_update_mesh( sr_object* object, sr_obj_mesh* mesh );     // Generate new vbo and ebo
void sr_object_update_model( sr_object* object, mat4 model );           // Just update in datatype 

void sr_object_draw( sr_object* object );                               // Draw object this frame
                                                                        
#endif

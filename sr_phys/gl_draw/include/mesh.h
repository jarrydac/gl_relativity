#ifndef SR_MESH
#define SR_MESH

#include "../lib/include/cglm/cglm.h"

typedef struct {
    vec4 position;
    vec3 normal;
} sr_mesh_vert;

typedef struct {
    unsigned int vbo_id;
    unsigned int ebo_id;
    unsigned int vao_id;    
    unsigned int elements_count;
} sr_mesh;

int sr_init_mesh(
        sr_mesh* mesh,
        int* indicies,
        int indicies_len,
        sr_mesh_vert* offsets,
        int offsets_len
    );

void sr_delete_mesh(sr_mesh*);


#endif

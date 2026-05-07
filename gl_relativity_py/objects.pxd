from .types cimport *

cdef extern from '../include/mesh.h':
    ctypedef struct sr_mesh_vert:
        vec4 position;
        vec3 normals;

    ctypedef struct sr_mesh:
        pass

    int sr_init_mesh(
            sr_mesh* mesh,
            int* indicies,
            int indicies_len,
            sr_mesh_vert* offsets,
            int offsets_len
        );

    void sr_delete_mesh(sr_mesh*);

cdef extern from '../include/objects.h':
    ctypedef struct sr_obj_wl:
        vec4* events; # MAX_WL_LEN 1024
        int length

    ctypedef struct sr_object:
        pass

    int sr_object_init( sr_object*, sr_obj_wl*, sr_mesh*, mat4 model, vec2 color )
    void sr_object_delete( sr_object* )

    void sr_object_update_wl( sr_object*, sr_obj_wl* )
    void sr_object_update_mesh( sr_object*, sr_mesh ) 
    void sr_object_update_model( sr_object*, mat4 model )  

    void sr_object_draw( sr_object* )
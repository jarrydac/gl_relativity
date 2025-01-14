#include "objects.h"

#include "include/glad/gl.h"
#include "shaders.h"

#define WLS_UNIT GL_TEXTURE0
#define WL_LENS_UNIT GL_TEXTURE0+1

static GLuint wls_tex;
static GLuint wl_lens_tex;
static int wls_count;

void sr_objects_init(void){
    glGenTextures(1, &wls_tex);
    glGenTextures(1, &wl_lens_tex);
    wls_count = 0;

    glActiveTexture(WLS_UNIT);
    glBindTexture(GL_TEXTURE_2D, wls_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
    glTexImage2D(GL_TEXTURE_2D, 
            0, GL_RGBA32F, 
            MAX_WL_LEN, MAX_WL_NUM, 
            0, GL_RGBA, GL_FLOAT, NULL
            );

    glActiveTexture(WL_LENS_UNIT);
    glBindTexture(GL_TEXTURE_1D, wl_lens_tex);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAX_LEVEL, 0);
    glTexImage1D(GL_TEXTURE_1D, 
            0, GL_R32I, 
            MAX_WL_NUM, 
            0, GL_RED_INTEGER, GL_INT, NULL
            );
}

// init
void sr_objects_render(void);   // call draw functions
                                
void sr_objects_close(void){
    glDeleteTextures(1, &wls_tex);
    glDeleteTextures(1, &wl_lens_tex);
}    

int sr_object_init( sr_object* object, sr_obj_wl* wl, sr_obj_mesh* mesh, mat4 model ){
    if(wls_count >= MAX_WL_NUM) return 1;   // TO MANY WLS.
    object->anchor_wl = wls_count++;        // Select next avaliable position TODO: manage free'd indicies
    sr_object_update_wl( object, wl );

    object->vbo_id = 0; // Initialise to 0, to show undeclared.
    object->ebo_id = 0;
    object->vao_id = 0;
    if( sr_object_update_mesh( object, mesh ) ) return 2;  

    sr_object_update_model( object, model );
    return 0;
}

void sr_object_delete( sr_object* object ){
    if( object->ebo_id ) glDeleteBuffers(1, &object->ebo_id );
    if( object->vbo_id ) glDeleteBuffers(1, &object->vbo_id );
    if( object->vao_id ) glDeleteVertexArrays(1, &object->vao_id );
};

void sr_object_update_wl( sr_object* object, sr_obj_wl* wl ){
    // Add wl data
    glBindTexture(GL_TEXTURE_2D, wls_tex);
    glTexSubImage2D(GL_TEXTURE_2D, 
            0, 
            0, object->anchor_wl, 
            MAX_WL_LEN, 1,
            GL_RGBA, GL_FLOAT,
            wl->events
        );
    
    // Add wl len
    glBindTexture(GL_TEXTURE_1D, wl_lens_tex);
    glTexSubImage1D(GL_TEXTURE_1D, 
            0, 
            object->anchor_wl, 
            1,
            GL_RED_INTEGER, GL_INT,
            &(wl->length)
        );
}           
                                                                        
int sr_object_update_mesh( sr_object* object, sr_obj_mesh* mesh ){
    // VAO
    if( object->vao_id ) glDeleteVertexArrays(1, &object->vao_id );
    glGenVertexArrays(1, &object->vao_id);
    glBindVertexArray(object->vao_id);

    // EBO
    if( object->ebo_id ) glDeleteBuffers(1, &object->ebo_id );
    glGenBuffers(1, &object->ebo_id);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, object->ebo_id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, mesh->indicies_len * sizeof(int), mesh->indicies, GL_STATIC_DRAW);
    object->elements_count = mesh->indicies_len;
    
    // VBO
    sr_obj_render_vert* verts = (sr_obj_render_vert*) malloc( sizeof(sr_obj_render_vert) * mesh->offsets_len );
    if(verts == NULL) return -1;

    for(int i=0; i<mesh->offsets_len; i++){
        glm_vec4_copy(mesh->offsets[i], verts[i].offset);
        verts[i].wl_index = object->anchor_wl;
    }
       
    if( object->vbo_id ) glDeleteBuffers(1, &object->vbo_id ); // Only delete the buffer after malloc
    glGenBuffers(1, &object->vbo_id);
    glBindBuffer(GL_ARRAY_BUFFER, object->vbo_id);
    glBufferData(GL_ARRAY_BUFFER, mesh->offsets_len * sizeof(sr_obj_render_vert), verts, GL_STATIC_DRAW);

    glVertexAttribPointer( 0, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof( sr_obj_render_vert ), 
            (void*) offsetof( sr_obj_render_vert, offset ) 
        );
    glEnableVertexAttribArray(0);
    glVertexAttribIPointer( 1, 1, 
            GL_INT,  
            sizeof( sr_obj_render_vert ), 
            (void*) offsetof( sr_obj_render_vert, wl_index ) 
        );
    glEnableVertexAttribArray(1);

    glBindVertexArray(0); // I dont trust myself.
    free(verts);

    return 0;
}
                             
void sr_object_update_model( sr_object* object, mat4 model ){
    glm_mat4_copy( model, object->model );   
}    

void sr_object_draw( sr_object* object ){
    sr_use_obj_program( object->model );

    glActiveTexture(WLS_UNIT);
    glBindTexture(GL_TEXTURE_2D, wls_tex);
    glActiveTexture(WL_LENS_UNIT);
    glBindTexture(GL_TEXTURE_1D, wl_lens_tex);

    glBindVertexArray( object->vao_id );

    glDrawElements(GL_TRIANGLES, object->elements_count, GL_UNSIGNED_INT, (void*)0);
}

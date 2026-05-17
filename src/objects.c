#include "../include/objects.h"

#include "../lib/include/glad/gl.h"
#include "../include/shaders.h"
#include "../include/lights.h"

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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // Why do i need to set these on my laptop??
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // Why do i need to set these on my laptop??
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE); // To avoid object flying into start position
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE); // To avoid object flying into start position
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0);
    glTexImage2D(GL_TEXTURE_2D, 
            0, GL_RGBA32F, 
            MAX_WL_LEN, MAX_WL_NUM, 
            0, GL_RGBA, GL_FLOAT, NULL
            );

    glActiveTexture(WL_LENS_UNIT);
    glBindTexture(GL_TEXTURE_1D, wl_lens_tex);
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST); // Why do i need to set these on my laptop??
    glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST); // Why do i need to set these on my laptop??
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

int sr_object_init( sr_object* object, sr_obj_wl* wl, sr_mesh* mesh, mat4 model, vec2 color ){
    if(wls_count >= MAX_WL_NUM) return 1;   // TO MANY WLS.
    object->anchor_wl = wls_count++;        // Select next avaliable position TODO: manage free'd indicies
    sr_object_update_wl( object, wl );

    object->mesh = mesh;
    
    glm_vec2_copy( color, object->color ); 

    sr_object_update_model( object, model );
    return 0;
}

void sr_object_delete( sr_object* object ){
    return;
}

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
    
    glm_vec3_copy(wl->initial_vel, object->wl_initial_vel);
    glm_vec3_copy(wl->final_vel, object->wl_final_vel);
}           
                                                                        
void sr_object_update_model( sr_object* object, mat4 model ){
    glm_mat4_copy( model, object->model );   
}    

void sr_object_draw( sr_object* object ){
    sr_use_obj_program( object->model, object, object->color );

    glActiveTexture(WLS_UNIT);
    glBindTexture(GL_TEXTURE_2D, wls_tex);
    glActiveTexture(WL_LENS_UNIT);
    glBindTexture(GL_TEXTURE_1D, wl_lens_tex);
    
    sr_lights_bind_textures();    

    glBindVertexArray( object->mesh->vao_id );

    glDrawElements(GL_TRIANGLES, object->mesh->elements_count, GL_UNSIGNED_INT, (void*)0);
}

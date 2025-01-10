#include "gl_draw.h"

#include <stdio.h>

#include "shaders.h"
#include "camera.h"
#include "objects.h"

int sr_draw_init( char* v_shader_str, char* f_shader_str, char* c_shader_str ){

    // GLAD Init.
    int version = gladLoaderLoadGL();
    if (version == 0) {
        printf("Failed to initialize OpenGL context\n");
        return -1;
    }
    printf("Loaded OpenGL %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));

    // Setup OpenGL state
    glViewport(0,0,800,800);
    glClearColor( 1.0, 1.0, 1.0, 1.0 );
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CLIP_DISTANCE0);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable( GL_BLEND );

    // init 
    sr_shaders_init( v_shader_str, f_shader_str );
    camera_init();
    sr_objects_init();

    return 0;
}


unsigned int sr_draw_mesh(void){
    return 0;
}

// This is inefficient, but convenient for drawing one point (for diagnostics?)
typedef void wl_t; 
unsigned int sr_draw_wl( wl_t* wl ){
    return 0;
    // Redo this.
}

unsigned int sr_render_mesh( 
        unsigned int anchor_buff, 
        unsigned int anchor_count,
        unsigned int vbo_buff,      // Vertex offsets from anchor
        unsigned int vbo_count,
        unsigned int ebo_buff,
        unsigned int ebo_count,
        mat4 model
    ){
    // Supercededed by objects.h
    return 0;
}

unsigned int sr_render(void){
    // Redo this.
    return 0;
}

unsigned int sr_clear(void){
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    return 0;
}

#include "../include/gl_draw.h"

#include <stdio.h>

int sr_draw_init( char* v_shader_str, char* f_shader_str, char* c_shader_str ){

    // GLAD Init.
    int version = gladLoaderLoadGL();
    if (version == 0) {
        printf("Failed to initialize OpenGL context\n");
        return 1;
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

void sr_clear(void){
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}

void sr_close(void); // TODO

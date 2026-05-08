#include "../include/gl_draw.h"
#include <stdio.h>

#undef SR_DEBUG

GLuint overlay_tex;
GLuint overlay_vao;

void pre_gl_call(const char *name, GLADapiproc apiproc, int len_arg, ...) {
    printf("Calling: %s at %p (%d arguments)\n", name, apiproc, len_arg);
}

int sr_draw_init( char* v_shader_str, char* f_shader_str, vec3 cie_data[471] ){

    // GLAD Init.
    int version = gladLoaderLoadGL();
    if (version == 0) {
        printf("Failed to initialize OpenGL context\n");
        return 1;
    }
    printf("Loaded OpenGL %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));

    #ifdef SR_DEBUG
        gladSetGLPreCallback(pre_gl_call);
    #endif

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
    sr_lights_init(cie_data);

    //Create overlay texture
    glGenTextures(1, &overlay_tex);
    glBindTexture(GL_TEXTURE_2D, overlay_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //Create overlay program
    sr_overlay_init();
    
    //create overlay vao
    glCreateVertexArrays(1,&overlay_vao);

    return 0;
}

void sr_clear(float r, float g, float b){
    glClearColor(r,g,b, 1.0);
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
}

void sr_close(void){

    //close 
    sr_lights_close();
    sr_objects_close();
}

void sr_overlay(char* data, uint width, uint height){
    sr_overlay_use();
    glBindVertexArray(overlay_vao);
    glActiveTexture(OVERLAY_UNIT);
    glBindTexture(GL_TEXTURE_2D,overlay_tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glDrawArrays(GL_TRIANGLE_STRIP,0,4);

    glBindTexture(GL_TEXTURE_2D,0);
}
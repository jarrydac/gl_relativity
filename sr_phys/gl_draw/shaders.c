#include "shaders.h"

#include <stdlib.h>
#include <stdio.h>

#include "camera.h"

static GLuint obj_program;
static struct {
    int model;
    int view;
    int proj;
    int t;
    int c;
} obj_program_uniforms;

static mat4 obj_model_ident;
static mat4 obj_proj_mat;

typedef struct {
    char* src;
    GLuint id;
    GLenum type;
    int loaded;
} sr_shader; 

int sr_load_shader( sr_shader* );
GLuint sr_link_program( sr_shader[], int count );

int sr_shaders_init( char* vertex_shader_src, char* fragment_shader_src ){
    // Load the obj shader program
    sr_shader obj_shaders[2];
    sr_shader obj_vertex_shader; 
    sr_shader obj_fragment_shader; 

    obj_vertex_shader.src = vertex_shader_src;
    obj_vertex_shader.type = GL_VERTEX_SHADER;
    obj_vertex_shader.loaded = 0;

    obj_fragment_shader.src = fragment_shader_src;
    obj_fragment_shader.type = GL_FRAGMENT_SHADER;
    obj_fragment_shader.loaded = 0;

    if( sr_load_shader( &obj_vertex_shader ) ) return 1;
    if( sr_load_shader( &obj_fragment_shader ) ) return 2;

    obj_shaders[0] = obj_vertex_shader;
    obj_shaders[1] = obj_fragment_shader;
    obj_program = sr_link_program( obj_shaders, 2 );
    if(!obj_program) return 3;

    // Find uniforms
    obj_program_uniforms.model = glGetUniformLocation(obj_program, "model");
    obj_program_uniforms.view = glGetUniformLocation(obj_program, "view");
    obj_program_uniforms.proj = glGetUniformLocation(obj_program, "projection");
    obj_program_uniforms.c = glGetUniformLocation(obj_program, "sr_c");
    obj_program_uniforms.t = glGetUniformLocation(obj_program, "time");

    // Create static matricies
    glm_mat4_identity(obj_model_ident);
    glm_perspective(glm_rad(45.0f), 1, 0.1f, 600.0f, obj_proj_mat); 

    return 0;
}

int sr_load_shader( sr_shader* shader ){
    int success;
    char infoLog[512];

    shader->id = glCreateShader( shader->type );
    glShaderSource(shader->id, 1, (char const* const*)&shader->src, NULL);
    glCompileShader(shader->id);

    glGetShaderiv(shader->id, GL_COMPILE_STATUS, &success);
    if(!success){
        glGetShaderInfoLog(shader->id, 512, NULL, infoLog);
        fprintf(stderr, "Failed Shader Compilation.\n" );
        fprintf(stderr, "%s", infoLog );
        return 1;
    }

    shader->loaded = 1;
    return 0;
}

GLuint sr_link_program( sr_shader* shaders, int num ){
    GLuint program;
    int success;
    char infoLog[512];

    program = glCreateProgram();

    for(int i=0; i<num; i++) glAttachShader(program, shaders[i].id);
    glLinkProgram(program);

    glGetProgramiv(program, GL_LINK_STATUS, &success);
    if(!success){
        glGetProgramInfoLog(program, 512, NULL, infoLog);
        fprintf(stderr, "Failed Shader Program Linking.\n" );
        fprintf(stderr, "%s", infoLog );
        return 0;
    }

    for(int i=0; i<num; i++) glDeleteShader(shaders[i].id);
    return program;
}

void sr_use_obj_program( mat4 model ){
    glUseProgram(obj_program);

    glUniform1f(obj_program_uniforms.c, camera_get_c());
    glUniform1f(obj_program_uniforms.t, camera_get_time());
    glUniformMatrix4fv(obj_program_uniforms.proj, 1, GL_FALSE, (float*)obj_proj_mat);

    mat4 view;
    camera_view_matrix( view );
    glUniformMatrix4fv(obj_program_uniforms.view, 1, GL_FALSE, (float*)view);

    glUniformMatrix4fv(obj_program_uniforms.model, 1, GL_FALSE, (float*)model);
}

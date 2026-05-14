#include "../include/overlay_program.h"

#include "../lib/include/glad/gl.h"
#include <stdio.h>

GLuint overlay_program;
GLuint layer_uniform;

const char* vert_shader_src = 
"#version 460 core\n"
"out vec2 v_tex;"
"uniform float layer;"
""
"const vec2 pos[4]=vec2[4](vec2(-1.0, 1.0),"
"                          vec2(-1.0,-1.0),"
"                          vec2( 1.0, 1.0),"
"                          vec2( 1.0,-1.0));"
""
"void main()"
"{"
"    v_tex=0.5*pos[gl_VertexID] + vec2(0.5);"
"    gl_Position=vec4(pos[gl_VertexID], layer, 1.0);"
"}";

const char* frag_shader_src = 
"#version 460 core\n"
"in vec2 v_tex;"
"layout (binding=4) uniform sampler2D texSampler;"
"out vec4 color;"
"void main()"
"{"
"    color=texture(texSampler, v_tex);"
"}";

int sr_overlay_init(){
    GLuint frag_shader_id;
    GLuint vert_shader_id;

    int success;
    char infoLog[512];

    frag_shader_id = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(frag_shader_id, 1, &frag_shader_src, NULL);
    glCompileShader(frag_shader_id);
    glGetShaderiv(frag_shader_id, GL_COMPILE_STATUS, &success);
    if(!success){
        glGetShaderInfoLog(frag_shader_id, 512, NULL, infoLog);
        fprintf(stderr, "Failed Shader Compilation.\n" );
        fprintf(stderr, "%s", infoLog );
        return 1;
    }

    vert_shader_id = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vert_shader_id, 1, &vert_shader_src, NULL);
    glCompileShader(vert_shader_id);
    glGetShaderiv(vert_shader_id, GL_COMPILE_STATUS, &success);
    if(!success){
        glGetShaderInfoLog(vert_shader_id, 512, NULL, infoLog);
        fprintf(stderr, "Failed Shader Compilation.\n" );
        fprintf(stderr, "%s", infoLog );
        return 1;
    }

    overlay_program = glCreateProgram();

    glAttachShader(overlay_program, vert_shader_id);
    glAttachShader(overlay_program, frag_shader_id);
    glLinkProgram(overlay_program);

    glGetProgramiv(overlay_program, GL_LINK_STATUS, &success);
    if(!success){
        glGetProgramInfoLog(overlay_program, 512, NULL, infoLog);
        fprintf(stderr, "Failed Shader Program Linking.\n" );
        fprintf(stderr, "%s", infoLog );
        return 2;
    }

    glDeleteShader(frag_shader_id);
    glDeleteShader(vert_shader_id);

    layer_uniform = glGetUniformLocation(overlay_program, "layer");

    return 0;
}

void sr_overlay_use(){
    glUseProgram(overlay_program);
}

void sr_overlay_set_layer(float layer){
    glUniform1f(layer_uniform,layer);
}
#include <stdio.h>
#include <string.h>

#include "camera.h"

#include "gl_draw.h"

#define MAX_POINTS 1048

static GLuint wl_vao;

static GLuint points_buff;
static int points_count;

static int model_loc;
static int proj_loc;
static int view_loc;
static int sr_c_loc;
static int time_loc;

static int sr_c_comp_loc;
static int time_comp_loc;
static int model_comp_loc;
static int view_comp_loc;
static int vbo_comp_offset_loc;

static float sr_c = 30.0f;

static unsigned int shader_program;
static unsigned int compute_program;

/* INIT */
int sr_draw_init( char* v_shader_str, char* f_shader_str, char* c_shader_str ){
    unsigned int v_shader;
    unsigned int f_shader;
    unsigned int c_shader;
    mat4 model;
    mat4 proj;

    // GLAD Init.
    int version = gladLoaderLoadGL();
    if (version == 0) {
        printf("Failed to initialize OpenGL context\n");
        return -1;
    }
    printf("Loaded OpenGL %d.%d\n", GLAD_VERSION_MAJOR(version), GLAD_VERSION_MINOR(version));

    //Load vertex computer program.
    c_shader = load_shader( c_shader_str, GL_COMPUTE_SHADER );
    if(!c_shader) return -1;
    unsigned int c_shader_a[1];
    c_shader_a[0] = c_shader;
    compute_program = make_shader_program( c_shader_a, 1 );
    glDeleteShader(c_shader);
    if(!compute_program) return -1;

    // Load Shader Program
    v_shader = load_shader( v_shader_str, GL_VERTEX_SHADER );
    f_shader = load_shader( f_shader_str, GL_FRAGMENT_SHADER );
    if(!v_shader) return -1;
    if(!f_shader) return -1;
    unsigned int shaders[2];
    shaders[0] = v_shader;
    shaders[1] = f_shader;
    shader_program = make_shader_program( shaders, 2 );
    glDeleteShader(v_shader);
    glDeleteShader(f_shader);
    if(!shader_program) return -1;
    glUseProgram(shader_program);

    // Locate uniforms
    model_loc = glGetUniformLocation(shader_program, "model");
    view_loc = glGetUniformLocation(shader_program, "view");
    proj_loc = glGetUniformLocation(shader_program, "projection");
    sr_c_loc = glGetUniformLocation(shader_program, "sr_c");
    time_loc = glGetUniformLocation(shader_program, "time");

    // Compute program uniforms
    model_comp_loc = glGetUniformLocation(compute_program, "model");
    view_comp_loc = glGetUniformLocation(compute_program, "view");
    sr_c_comp_loc = glGetUniformLocation(compute_program, "sr_c");
    time_comp_loc = glGetUniformLocation(compute_program, "time");
    vbo_comp_offset_loc = glGetUniformLocation(compute_program, "vbo_offset");

    // Init static model and perspective.
    glm_mat4_identity(model);
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, (float*)model);
    glm_perspective(glm_rad(45.0f), 1, 0.1f, 10000.0f, proj); 
    glUniformMatrix4fv(proj_loc, 1, GL_FALSE, (float*)proj);

    glUseProgram(compute_program);
    glUniformMatrix4fv(model_comp_loc, 1, GL_FALSE, (float*)model);
    glUseProgram(shader_program);

    // Setup OpenGL state
    glViewport(0,0,800,800);
    glClearColor( 1.0, 1.0, 1.0, 1.0 );
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CLIP_DISTANCE0);

    // Stray WL buffer.
    glGenBuffers(1, &points_buff);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, points_buff);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(render_vert_t)*MAX_POINTS, NULL, GL_STATIC_DRAW);
    points_count = 0;

    // VAO for wl
    glGenVertexArrays(1, &wl_vao);
    glBindVertexArray(wl_vao);
    glVertexAttribPointer(0, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof(render_vert_t), (void*)( offsetof(render_vert_t, a) ) 
            );  
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof(render_vert_t), (void*)( offsetof(render_vert_t, b) ) 
            );  
    glEnableVertexAttribArray(1);
    glBindVertexArray(0);

                              
    return 0;
}

unsigned int load_shader(char* str, GLenum type){
    unsigned int shader;
    int success;
    char infoLog[512];

    shader = glCreateShader(type); // GL_VERTEX_SHADER
    glShaderSource(shader, 1, (char const* const*)&str, NULL);
    glCompileShader(shader);
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);

    if(!success){
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        fprintf(stderr, "Failed Shader Compilation.\n" );
        fprintf(stderr, "%s", infoLog );
        return 0;
    }

    return shader;
}

unsigned int make_shader_program( GLuint shaders[], int num ){
    unsigned int shader_program;
    int success;
    char infoLog[512];

    shader_program = glCreateProgram();

    for(int i=0; i<num; i++){
        glAttachShader(shader_program, shaders[i]);
    }

    glLinkProgram(shader_program);

    glGetProgramiv(shader_program, GL_LINK_STATUS, &success);
    if(!success){
        glGetProgramInfoLog(shader_program, 512, NULL, infoLog);
        fprintf(stderr, "Failed Shader Program Linking.\n" );
        fprintf(stderr, "%s", infoLog );
        return 0;
    }

    return shader_program;
}

// Drawing

float sr_interval( vec4 a, vec4 b ){
    vec4 diff;      // Difference
    glm_vec4_sub(b, a, diff);
    
    float t = diff[0];
    float x = diff[1];
    float y = diff[2];
    float z = diff[3];

    return sr_c*sr_c*t*t - x*x - y*y - z*z;
}

unsigned int sr_draw_mesh(void){
    return 0;
}

// This is inefficient, but convenient for drawing one point (for diagnostics?)
unsigned int sr_draw_wl( wl_t* wl ){
    // Load wl.
    GLuint wl_buff;
    glGenBuffers(1, &wl_buff);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, wl_buff);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(vec4)*wl->vert_count, (void*) wl->verticies, GL_STATIC_READ);

    // Init a length 1 zero offset buffer
    vec4 zero_offset = GLM_VEC4_ZERO_INIT;
    GLuint offset_buff;
    glGenBuffers(1, &offset_buff);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, offset_buff);
    glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(vec4), (void*) zero_offset, GL_STATIC_READ);

    glUseProgram(compute_program);

    // Setup Uniforms
    mat4 view;
    camera_view_matrix(view);
    mat4 model = GLM_MAT4_IDENTITY_INIT;
    
    glUniform1f(sr_c_comp_loc, sr_c);
    glUniform1f(time_comp_loc, camera_get_time());
    glUniformMatrix4fv(view_comp_loc, 1, GL_FALSE, (float*)view);
    glUniformMatrix4fv(model_comp_loc, 1, GL_FALSE, (float*)model);
    glUniform1ui(vbo_comp_offset_loc, points_count);

    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, wl_buff);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, points_buff);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, offset_buff);

    glDispatchCompute(wl->vert_count, 1, 1);

    glDeleteBuffers(1, &wl_buff);
    glDeleteBuffers(1, &offset_buff);
    points_count++;

    return 0;
}

GLuint sr_make_vec4_buffer( vec4 vecs[], unsigned int count ){
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, count*sizeof(vec4), vecs, GL_STATIC_READ);
    return buffer;
}

GLuint sr_make_int_buffer( unsigned int vals[], unsigned int count ){
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, buffer);
    glBufferData(GL_SHADER_STORAGE_BUFFER, count*sizeof(unsigned int), vals, GL_STATIC_READ);
    return buffer;
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
    
    mat4 view;
    GLuint draw_buff;

    // Setup the program
    camera_view_matrix(view);
    glUseProgram(compute_program);

    glUniform1f(sr_c_comp_loc, sr_c);
    glUniform1f(time_comp_loc, camera_get_time());
    glUniform1ui(vbo_comp_offset_loc, 0);

    glUniformMatrix4fv(view_comp_loc, 1, GL_FALSE, (float*)view);
    glUniformMatrix4fv(model_comp_loc, 1, GL_FALSE, (float*)model);

    // Setup drawing buffer.
    glGenBuffers(1, &draw_buff);
    glBindBuffer(GL_ARRAY_BUFFER, draw_buff);
    glBindVertexArray(wl_vao);
    glBufferData(GL_ARRAY_BUFFER, vbo_count*sizeof(render_vert_t), NULL, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof(render_vert_t), (void*)( offsetof(render_vert_t, a) ) 
            );  
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof(render_vert_t), (void*)( offsetof(render_vert_t, b) ) 
            );  
    glEnableVertexAttribArray(1);

    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, anchor_buff);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, draw_buff);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 3, vbo_buff);

    glDispatchCompute(anchor_count, vbo_count, 1);
    glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT);

    glUseProgram(shader_program);

    glBindBuffer(GL_ARRAY_BUFFER, draw_buff);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo_buff);

    glUniformMatrix4fv(view_loc, 1, GL_FALSE, (float*)view);
    mat4 identity;
    glm_mat4_identity(identity);
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, (float*)identity);
    glUniform1f(sr_c_loc, sr_c);
    glUniform1f(time_loc, camera_get_time());

    glDrawElements(GL_TRIANGLES, ebo_count, GL_UNSIGNED_INT, 0);

    glDeleteBuffers(1, &draw_buff);

    return 0;
}

unsigned int sr_render(void){
    mat4 model = GLM_MAT4_IDENTITY_INIT;
    mat4 view;
    camera_view_matrix(view);

    // Shader program
    glUseProgram(shader_program);

    // Setup uniforms
    glUniform1f(sr_c_loc, sr_c);
    glUniform1f(time_loc, camera_get_time());
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, (float*)model);
    glUniformMatrix4fv(view_loc, 1, GL_FALSE, (float*)view);

    glBindBuffer(GL_ARRAY_BUFFER, points_buff);
    glBindVertexArray(wl_vao);
    glVertexAttribPointer(0, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof(render_vert_t), (void*)( offsetof(render_vert_t, a) ) 
            );  
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 4, 
            GL_FLOAT, GL_FALSE, 
            sizeof(render_vert_t), (void*)( offsetof(render_vert_t, b) ) 
            );  
    glEnableVertexAttribArray(1);

    glPointSize(3.0f);

    glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT); // Ensure all computes have finished
                                                        
    glDrawArrays(GL_POINTS, 0, points_count);

    points_count = 0;
    return 0;
}

unsigned int sr_clear(void){
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    return 0;
}

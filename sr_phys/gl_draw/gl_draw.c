#include <stdio.h>
#include <string.h>

#include "gl_draw.h"

#define WL_VBO_SIZE 32768
#define WLS_BUFF_SIZE 1048576

#define MAX_WL 63

static camera_t camera;
static float sr_c;

static GLuint wl_vao;
static GLuint wl_vbo;

static unsigned int wl_vbo_index;
static unsigned int longest_wl;

static GLuint wls_buff;

static int model_loc;
static int proj_loc;
static int view_loc;
static int sr_c_loc;
static int time_loc;

static int sr_c_comp_loc;
static int time_comp_loc;
static int wl_lens_loc;
static int model_comp_loc;
static int view_comp_loc;

static float sr_c = 30.0f;

static unsigned int shader_program;
static unsigned int compute_program;

/* CAMERA */
void camera_init(void){
    float up_a[] = {0.0f, 1.0f, 0.0f};
    float pos_a[] = {0.0f, 0.0f, 0.0f};
    glm_vec3_make(up_a, camera.up);
    glm_vec3_make(pos_a, camera.position);
    camera.pitch = glm_rad( 0.0f );
    camera.yaw = glm_rad( -90.0f );
    camera.time = 0.0f;
}

void camera_get_pos( vec3 pos ){
    glm_vec3_copy( camera.position, pos );
}

void camera_set_pos( vec3 pos ){
    glm_vec3_copy( pos, camera.position );
}

void camera_get_angle( float* pitch, float* yaw ){
    *pitch = camera.pitch;
    *yaw = camera.yaw;
}

void camera_set_angle( float pitch, float yaw ){
    camera.pitch = pitch;
    camera.yaw = yaw;
}

void camera_set_time( float t ){
    camera.time = t;
}

float camera_get_time(void){
    return camera.time;
}

void camera_look_direction(float pitch, float yaw, vec3 direction){
    //if(pitch > 89.0f) pitch = 89.0f;
    //if(pitch < -89.0f) pitch = -89.0f;
    direction[0] = cos(yaw) * cos(pitch);
    direction[1] = sin(pitch);
    direction[2] = sin(yaw) * cos(pitch);
    glm_normalize(direction);
    //glm_vec3_scale(direction, -1.0, direction);
}

void camera_view_matrix( mat4 view ){
    vec3 camera_dir;
    camera_look_direction(camera.pitch, camera.yaw, camera_dir);
    glm_look(camera.position, camera_dir, camera.up, view);
}



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

    // Compute program
    model_comp_loc = glGetUniformLocation(compute_program, "model");
    view_comp_loc = glGetUniformLocation(compute_program, "view");
    sr_c_comp_loc = glGetUniformLocation(compute_program, "sr_c");
    time_comp_loc = glGetUniformLocation(compute_program, "time");

    // Init static model and perspective.
    glm_mat4_identity(model);
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, (float*)model);
    glm_perspective(glm_rad(45.0f), 1, 0.1f, 10000.0f, proj); 
    //glm_ortho(-400.0f, 400.0f, -200.0f, 200.0f, 1.0f, 1000.0f, proj);
    glUniformMatrix4fv(proj_loc, 1, GL_FALSE, (float*)proj);

    glUseProgram(compute_program);
    glUniformMatrix4fv(model_comp_loc, 1, GL_FALSE, (float*)model);
    glUseProgram(shader_program);

    // Setup OpenGL state
    glViewport(0,0,800,800);
    glClearColor( 1.0, 1.0, 1.0, 1.0 );
    //glEnable(GL_DEPTH_TEST);

    // General wl buffer object
    glGenVertexArrays(1, &wl_vao);
    glBindVertexArray(wl_vao);

    glGenBuffers(1, &wl_vbo); // Generate one buff to VBO    
                              
    glBindBuffer(GL_ARRAY_BUFFER, wl_vbo);

    // Init empty vbo of size ### for wls.
    glBufferData(GL_ARRAY_BUFFER, WL_VBO_SIZE, NULL, GL_DYNAMIC_DRAW);
    wl_vbo_index = 0;

    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, sizeof(render_vert_t), (void*)( offsetof(render_vert_t, a) ) );  
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, sizeof(render_vert_t), (void*)( offsetof(render_vert_t, b) ) );  
    glEnableVertexAttribArray(1);


    // Getting the computer buffer ready
    glGenBuffers(1, &wls_buff);
    glBindBuffer(GL_SHADER_STORAGE_BUFFER, wls_buff);
    glBufferData(GL_SHADER_STORAGE_BUFFER, WLS_BUFF_SIZE, NULL, GL_DYNAMIC_READ);
                              
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

unsigned int sr_draw_wl( wl_t* wl ){
    render_vert_t render_vert;

    longest_wl = wl->vert_count > longest_wl ?  wl->vert_count : longest_wl;

    glBindBuffer(GL_SHADER_STORAGE_BUFFER, wls_buff);
    glBufferSubData(GL_SHADER_STORAGE_BUFFER, wl_vbo_index*(MAX_WL+1)*sizeof(vec4), sizeof(int), &wl->vert_count );
    glBufferSubData(GL_SHADER_STORAGE_BUFFER, (wl_vbo_index*(MAX_WL+1)+1)*sizeof(vec4), wl->vert_count*sizeof(vec4), wl->verticies );

    wl_vbo_index++;

    return 0;
}

unsigned int sr_render(void){
    mat4 view;
    // Camera position setup;
    camera_view_matrix(view);

    // WLs Compute
    glUseProgram(compute_program);
    glUniform1f(sr_c_comp_loc, sr_c);
    glUniform1f(time_comp_loc, camera.time);
    glUniformMatrix4fv(view_comp_loc, 1, GL_FALSE, (float*)view);

    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 1, wls_buff);
    glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 2, wl_vbo);

    glDispatchCompute(longest_wl, (wl_vbo_index+63)/64, 1);
    glMemoryBarrier(GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT);

    // Shader program
    glUseProgram(shader_program);
    glBindVertexArray(wl_vao);
    glBindBuffer(GL_ARRAY_BUFFER, wl_vbo);
    glUniformMatrix4fv(view_loc, 1, GL_FALSE, (float*)view);

    // Set Speed of Light Uniform
    glUniform1f(sr_c_loc, sr_c);
    glUniform1f(time_loc, camera.time);

    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glPointSize(3.0f);
    glDrawArrays(GL_POINTS, 0, wl_vbo_index);

    wl_vbo_index = 0; // Restart vertex buffer.
    longest_wl = 0;

    return 0;
}

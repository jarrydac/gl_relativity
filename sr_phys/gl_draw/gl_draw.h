#include "include/glad/gl.h"
#include "include/cglm/cglm.h"

struct camera_t {
    float time;
    vec3 position;
    float pitch;
    float yaw;
    vec3 up;
};

typedef struct camera_t camera_t;

// Init functions.
int sr_draw_init( char* v_shader_str, char* f_shader_str, char* c_shader_str );

// Load a shader of type from str
unsigned int load_shader(char* str, GLenum type);
unsigned int make_shader_program( GLuint shaders[], int num );

void camera_init(void);
void camera_set_time( float time );
void camera_set_pos( vec3 pos );
void camera_set_angle( float pitch, float yaw );
float camera_get_time(void);
void camera_get_pos( vec3 pos );
void camera_get_angle( float* pitch, float* yaw);
void camera_look_direction(float pitch, float yaw, vec3 direction);
void camera_view_matrix( mat4 view );

/* Drawing Functions */
typedef struct {
    vec4 a;
    vec4 b;
} render_vert_t;

typedef enum { FINITE, INFINITE } finite_opt;
typedef struct {
    vec4* verticies;
    unsigned int vert_count;
    finite_opt finite;
} wl_t;

float sr_interval( vec4 a, vec4 b );
unsigned int sr_draw_wl( wl_t* wl );
unsigned int sr_render(void);

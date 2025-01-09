#include "include/glad/gl.h"
#include "include/cglm/cglm.h"


// Init functions.
int sr_draw_init( char* v_shader_str, char* f_shader_str, char* c_shader_str );

// Load a shader of type from str
unsigned int load_shader(char* str, GLenum type);
unsigned int make_shader_program( GLuint shaders[], int num );


GLuint sr_make_int_buffer( unsigned int vals[], unsigned int count );
GLuint sr_make_vec4_buffer( vec4 vecs[], unsigned int count );
unsigned int sr_render_mesh( 
        unsigned int anchor_buff, 
        unsigned int anchor_count,
        unsigned int vbo_buff,      
        unsigned int vbo_count,
        unsigned int ebo_buff,
        unsigned int ebo_count,
        mat4 model
    );

/* Drawing Functions */
typedef struct {
    vec4 pos;
    float interval;
    float padding[3];
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
unsigned int sr_clear(void);

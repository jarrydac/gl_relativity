from .types cimport *

cdef extern from '../include/gl_draw.h':
    int sr_draw_init( 
        char* v_shader,  
        char* f_shader, 
        vec3[471] cie_data
        )

    void sr_close()

    void sr_clear(float r, float g, float b)

    void sr_overlay(char* data, int width, int height)
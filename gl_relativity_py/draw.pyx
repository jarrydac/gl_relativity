import numpy as np

def init():
    vertex_shader = open('shaders/wl_vert_shader.glsl', 'r')
    fragment_shader = open('shaders/f_shader.frag.glsl', 'r')
    cie = np.loadtxt('CIE_xyz_1931_2deg.csv', delimiter=",", usecols=(1,2,3))

    cdef vec3[471] cie_data = np.ascontiguousarray(cie)

    sr_draw_init( 
        vertex_shader.read().encode(), 
        fragment_shader.read().encode(), 
        cie_data
    )

def close():
    sr_close()
    
# Clear for next pass
def clear( r=1.0, g=1.0, b=1.0 ):
    sr_clear(r,g,b)
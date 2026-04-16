#cython: language_level=3
import copy
import math
import numpy as np
cimport numpy as cnp
import trimesh

import cython
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

camera = None
c = 30.0

BOX_MESH = None;
SPHERE_MESH = None;

IDENTITY= np.array([
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
    ])

ctypedef float vec2[2]
ctypedef float vec3[3]
ctypedef float vec4[4]
ctypedef vec4 mat4[4];

cdef extern from 'include/gl_draw.h':
    int sr_draw_init( 
        char* v_shader,  
        char* f_shader, 
        char* c_shader,
        vec3[471] cie_data
        )
    void sr_close();

    void sr_clear(float r, float g, float b);

cdef extern from 'include/camera.h':
    void camera_init();

    void camera_get_pos( vec3 pos );
    void camera_set_pos( vec3 pos );
    
    void camera_get_vel( vec3 velocity );
    void camera_set_vel( const vec3 velocity );

    void camera_get_angle( float* pitch, float* yaw);
    void camera_set_angle( float pitch, float yaw );
    
    float camera_get_time();
    void camera_set_time( float time );

    float camera_get_c();
    void camera_set_c( float );

    void camera_set_lorentz( mat4 );
    void camera_get_lorentz( mat4 );

cdef extern from 'include/mesh.h':
    ctypedef struct sr_mesh_vert:
        vec4 position;
        vec3 normals;

    ctypedef struct sr_mesh:
        pass

    int sr_init_mesh(
            sr_mesh* mesh,
            int* indicies,
            int indicies_len,
            sr_mesh_vert* offsets,
            int offsets_len
        );

    void sr_delete_mesh(sr_mesh*);

cdef extern from 'include/objects.h':
    ctypedef struct sr_obj_wl:
        vec4* events; # MAX_WL_LEN 128
        int length;

    ctypedef struct sr_object:
        pass

    int sr_object_init( sr_object*, sr_obj_wl*, sr_mesh*, mat4 model, vec2 color );
    void sr_object_delete( sr_object* );

    void sr_object_update_wl( sr_object*, sr_obj_wl* );      
    void sr_object_update_mesh( sr_object*, sr_mesh );  
    void sr_object_update_model( sr_object*, mat4 model );  

    void sr_object_draw( sr_object* );
    
cdef extern from 'include/lights.h':
    ctypedef struct sr_light:
        pass
    ctypedef struct sr_light_discrete_spectrum:
        pass
    ctypedef struct sr_light_continuous_spectrum:
        pass

    int sr_lights_add(sr_light* light);
    
    int sr_lights_discrete_spectrum_init(
        sr_light_discrete_spectrum* spec,
        vec2* peaks,
        int len
    )

    int sr_light_init(
        sr_light* light, 
        vec3 pos,
        sr_light_continuous_spectrum* cont_spectrum, 
        sr_light_discrete_spectrum* disc_spectrum 
    );
    
    void sr_lights_discrete_spectrum_delete(sr_light_discrete_spectrum* spec);
    
    
    int sr_lights_continuous_spectrum_init(
        sr_light_continuous_spectrum* spec, 
        float samples[100]
    );
    
    void sr_lights_continuous_spectrum_delete(sr_light_continuous_spectrum* spec);
    
def lorentz_matrix(vel):
    v = np.linalg.norm( vel )
    gamma = 1/(math.sqrt(1-(v**2/c**2)))
    gamma_f = (gamma**2)/(1+gamma)

    # Wikipeda... Lorentz Transforms
    beta_x = vel[0]/c
    beta_y = vel[1]/c
    beta_z = vel[2]/c

    matrix = [
            [ gamma, -gamma*beta_x, -gamma*beta_y, -gamma*beta_z ],
            [ -gamma*beta_x, 1 + (gamma_f*beta_x**2), gamma_f*beta_x*beta_y, gamma_f*beta_x*beta_z ],
            [ -gamma*beta_y, gamma_f*beta_x*beta_y, 1 + (gamma_f*beta_y**2), gamma_f*beta_y*beta_z ],
            [ -gamma*beta_z, gamma_f*beta_x*beta_z, gamma_f*beta_y*beta_z, 1 + (gamma_f*beta_z**2) ]
            ]

    return np.array(matrix, dtype='f')

# Camera
class _Camera:
    def __init__(self):
        camera_init()

    @property
    def pos(self):
        cdef vec3 pos
        camera_get_pos( pos )
        return pos

    @property
    def vel(self):
        cdef vec3 vel
        camera_get_vel( vel )
        return self.vel

    @property
    def angle( self ):
        cdef float pitch 
        cdef float yaw
        camera_get_angle( &pitch, &yaw )
        return (pitch, yaw)

    @property 
    def time( self ):
        return camera_get_time()

    @property
    def lorentz_matrix( self ):
        cdef mat4 arr; 
        camera_get_lorentz( arr )
        return arr;

    @pos.setter
    def pos( self, vec3 pos ):
        camera_set_pos( pos )

    @angle.setter
    def angle( self, angle ):
        camera_set_angle( angle[0], angle[1] )

    @time.setter
    def time( self, time ):
        camera_set_time(time)

    @vel.setter
    def vel(self, vec3 vel):
        camera_set_vel( vel )

        lorentz_transform = lorentz_matrix(vel)
        cdef mat4 arr = np.ascontiguousarray(lorentz_transform, dtype='f')
        camera_set_lorentz( <mat4> arr )


# An (immutable) mesh of verticies and indicies
cdef class Mesh:
    cdef sr_mesh* thisptr

    def __cinit__(self, offsets, normals, indicies):
        cdef int offsets_len = len(offsets)
        cdef int indicies_len = len(indicies)

        cdef sr_mesh_vert* offset_array = <sr_mesh_vert*> malloc( sizeof(sr_mesh_vert)*offsets_len)
        cdef int* index_array = <int*> malloc( sizeof(int)*indicies_len)

        self.thisptr = <sr_mesh*> malloc( sizeof(sr_mesh) )

        if NULL in (self.thisptr, offset_array, index_array):
            raise MemoryError()

        print(normals)

        # Read in data
        for i in range( offsets_len ):
            # Position
            offset_array[i].position[0] = offsets[i][0]
            offset_array[i].position[1] = offsets[i][1]
            offset_array[i].position[2] = offsets[i][2]
            offset_array[i].position[3] = offsets[i][3]
            
            #Velocity
            offset_array[i].position[4] = normals[i][0]
            offset_array[i].position[5] = normals[i][1]
            offset_array[i].position[6] = normals[i][2]

        for i in range( indicies_len ):
            index_array[i] = indicies[i]

        sr_init_mesh(self.thisptr, 
                     index_array, indicies_len,
                     offset_array, offsets_len
                     )

    def __dealloc__(self):
        if self.thisptr is not NULL:
            sr_delete_mesh( self.thisptr )

    cdef sr_mesh* get_pointer(self):
        return self.thisptr

    @staticmethod
    def from_trimesh(mesh):
        offsets = np.array([[0, v[0], v[1], v[2]] for v in mesh.vertices])
        normals = np.array([[v[0], v[1], v[2]] for v in mesh.vertex_normals])
        indicies = np.array([i for face in mesh.faces for i in face]) # the pyhton way of squashing a list??
        return Mesh(offsets, normals, indicies)

    @staticmethod
    def from_file(file):
        mesh = trimesh.load(file, force="mesh")
        return Mesh.from_trimesh(mesh)
        
# Read a WL into an sr_ob_wl on the heap.
cdef sr_obj_wl* _wl_to_obj_wl_ptr(wl):
    global c

    cdef sr_obj_wl* wl_ptr = <sr_obj_wl*> malloc( sizeof(sr_obj_wl) ) # note in objects.h array is fixed size so it is of course already allocated now.
    if wl_ptr is NULL:
        raise MemoryError()

    wl_ptr.length = len(wl._events)

    if wl_ptr.length > 1023:    
        raise ValueError(f"WL too long! {wl_ptr.length}")
    cdef cnp.ndarray contiguous_events = np.ascontiguousarray(wl._events, dtype='f')
    memcpy(wl_ptr.events, contiguous_events.data, wl_ptr.length*sizeof(vec4))

    #for i in range( wl_ptr.length ):
    #    event = wl.events[i]
    #    wl_ptr.events[i][0] = event.vec.t/c
    #    wl_ptr.events[i][1] = event.vec.x
    #    wl_ptr.events[i][2] = event.vec.y
    #    wl_ptr.events[i][3] = event.vec.z

    return wl_ptr

# A (moveable) object, containing the minimum required data to draw.
# ie. an anchoring worldline, a mesh and a model matrix
cdef class Object:
    cdef sr_object* thisptr
    cdef public wl

    def __cinit__(self, wl, Mesh mesh, model=IDENTITY, color=np.array([1.0,500.0])):
        # Break all the args down to appropriate structs
        cdef sr_obj_wl* wl_ptr = _wl_to_obj_wl_ptr(wl); 
        cdef sr_mesh* mesh_ptr = mesh.get_pointer();
        cdef mat4 model_mat4 = np.ascontiguousarray(model, dtype="f")
        cdef vec2 color_vec2 = np.ascontiguousarray(color, dtype="f")
        
        cdef sr_object* obj = <sr_object*> malloc( sizeof(sr_object) )
        if obj is NULL:
            raise MemoryError
        if sr_object_init(obj, wl_ptr, mesh_ptr, model_mat4, color_vec2):
            raise Exception("Failed to init Object")
        self.thisptr = obj

        # These are all copied in so we can destroy these.
        free(wl_ptr)

        self.wl = wl

    def __dealloc__(self):
        if self.thisptr is not NULL:
            sr_object_delete( self.thisptr )

    def _update_wl(self):
        cdef sr_obj_wl* wl_ptr = _wl_to_obj_wl_ptr(self.wl)
        sr_object_update_wl(self.thisptr, wl_ptr)
        free(wl_ptr)

    def draw(self):
        if self.wl.dirty:
            self._update_wl()

        if self.thisptr is not NULL:
            sr_object_draw(self.thisptr);

# Lights
cdef class Light:
    cdef sr_light* thisptr
    cdef sr_light_discrete_spectrum* disc_spec
    cdef sr_light_continuous_spectrum* cont_spec

    def __cinit__(self, vec3 pos, cont_spec, peaks):
        cdef float[:,::1] peak_arr;
        cdef float[100] samples; 

        self.thisptr = <sr_light*> malloc( sizeof(sr_light) )
        self.disc_spec = NULL
        self.cont_spec = NULL
                    
        cdef vec3 pos_vec = np.ascontiguousarray(pos, dtype="f")
        
        if self.thisptr is NULL:
            raise MemoryError

        # Discrete spectra
        if peaks is not None:
            print("peaks")
            self.disc_spec = <sr_light_discrete_spectrum*> \
                malloc( sizeof(sr_light_discrete_spectrum) )
            if self.disc_spec is NULL:
                raise MemoryError

            peak_arr = np.ascontiguousarray(peaks, dtype="f")
            if( sr_lights_discrete_spectrum_init( 
                self.disc_spec, 
                <vec2*> &peak_arr[0][0],
                peaks.shape[0] 
                ) ):
                raise Exception("Could not init discrete spectrum")

        # Continuous Spectrum
        if cont_spec is not None:
            print("cont")
            self.cont_spec = <sr_light_continuous_spectrum*> \
                        malloc( sizeof(sr_light_continuous_spectrum) )
            if self.cont_spec is NULL:
                raise MemoryError

            for i in range(100):
                print(i)
                #samples[i] = cont_spec( (300+5*i)*1e-9 )
                samples[i] = cont_spec( math.exp(-i/3) )
            
            if ( sr_lights_continuous_spectrum_init(
                self.cont_spec,
                samples
            ) ):
                raise Exception("Could not init cont spectrum")
        
        if( sr_light_init( 
            self.thisptr, 
            pos_vec,
            self.cont_spec, 
            self.disc_spec, 
            ) ):
            raise Exception("Could not initialise light")

        sr_lights_add( self.thisptr )
        
    def __dealloc__(self):
        if self.disc_spec is not NULL:
            sr_lights_discrete_spectrum_delete( self.disc_spec )
            free( self.disc_spec ) 
            self.disc_spec = NULL
        if self.cont_spec is not NULL:
            sr_lights_continuous_spectrum_delete( self.cont_spec )
            free( self.cont_spec ) 
            self.cont_spec = NULL

        if self.thisptr is not NULL:
            free( self.thisptr ) 
            self.thisptr = NULL
        

# INIT
def init():
    global camera
    global BOX_MESH
    global SPHERE_MESH
    camera = _Camera()

    v_shader = open('shaders/wl_vert_shader.glsl', 'r')
    f_shader = open('shaders/f_shader.frag.glsl', 'r')
    
    cie = np.loadtxt('CIE_xyz_1931_2deg.csv', delimiter=",", usecols=(1,2,3))
    cdef vec3[471] cie_data = np.ascontiguousarray(cie)

    sr_draw_init( 
        v_shader.read().encode(), 
        f_shader.read().encode(), 
        '',
        cie_data
    )

    camera_set_c(c);

    BOX_MESH = Mesh.from_trimesh( trimesh.primitives.Box(
        extents=[1,1,1],
        transform=[
        [1,0,0,0.5],
        [0,1,0,0.5],
        [0,0,1,0.5],
        [0,0,0,1]
            ]
        ).to_mesh() ) 

    SPHERE_MESH = Mesh.from_trimesh( trimesh.primitives.Sphere(
        radius=1
        ).to_mesh() ) 
    
    return;

# Clear for next pass
def clear( r=1.0, g=1.0, b=1.0 ):
    sr_clear(r,g,b)

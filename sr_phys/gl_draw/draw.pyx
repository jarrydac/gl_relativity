#cython: language_level=3
import copy
import pygame
import math
import numpy as np
import trimesh

import cython
from libc.stdlib cimport malloc, free

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

ctypedef float vec3[3]
ctypedef float vec4[4]
ctypedef vec4 mat4[4];

cdef extern from 'include/gl_draw.h':
    int sr_draw_init( char* v_shader,  char* f_shader, char* c_shader )
    void sr_close();

    void sr_clear();

cdef extern from 'include/camera.h':
    void camera_init();

    void camera_get_pos( vec3 pos );
    void camera_set_pos( vec3 pos );

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

    int sr_object_init( sr_object*, sr_obj_wl*, sr_mesh*, mat4 model );
    void sr_object_delete( sr_object* );

    void sr_object_update_wl( sr_object*, sr_obj_wl* );      
    void sr_object_update_model( sr_object*, mat4 model );  

    void sr_object_draw( sr_object* );

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

    @lorentz_matrix.setter
    def lorentz_matrix(self, mat):
        #cdef mat4 arr = <mat4> _np_to_mat4(mat);
        cdef mat4 arr = np.ascontiguousarray(mat, dtype='f')
        camera_set_lorentz( <mat4> arr )
        #free( arr )

# Read a WL into an sr_ob_wl on the heap.
cdef sr_obj_wl* _wl_to_obj_wl_ptr(wl):
    global c

    cdef sr_obj_wl* wl_ptr = <sr_obj_wl*> malloc( sizeof(sr_obj_wl) ) # note in objects.h array is fixed size so it is of course already allocated now.
    if wl_ptr is NULL:
        raise MemoryError()

    wl_ptr.length = len(wl.events)
    
    for i in range( wl_ptr.length ):
        event = wl.events[i]
        wl_ptr.events[i][0] = event.vec.t/c
        wl_ptr.events[i][1] = event.vec.x
        wl_ptr.events[i][2] = event.vec.y
        wl_ptr.events[i][3] = event.vec.z

    return wl_ptr

cdef sr_mesh* _np_offset_indicies_to_mesh(offsets, indicies):
    cdef sr_mesh* mesh_ptr = <sr_mesh*> malloc( sizeof(sr_mesh) )
    if mesh_ptr is NULL:
        raise MemoryError()

    cdef int offsets_len = len(offsets)
    cdef int indicies_len = len(indicies)

    cdef sr_mesh_vert* offsets_a = <sr_mesh_vert*> malloc( sizeof(sr_mesh_vert)*offsets_len)
    if offsets_a is NULL:
        raise MemoryError()
    for i in range( offsets_len ):
        offsets_a[i].position[0] = offsets[i][0]
        offsets_a[i].position[1] = offsets[i][1]
        offsets_a[i].position[2] = offsets[i][2]
        offsets_a[i].position[3] = offsets[i][3]

    cdef int* indicies_a = <int*> malloc( sizeof(int)*indicies_len)
    if indicies_a is NULL:
        raise MemoryError()
    for i in range( indicies_len ):
        indicies_a[i] = indicies[i]

    sr_init_mesh(mesh_ptr, 
                 indicies_a, indicies_len,
                 offsets_a, offsets_len
                 )
    
    return mesh_ptr

cdef float* _np_to_mat4(mat):
    # mat size checking?
    cdef mat4 cmat = <mat4> malloc( 16 * cython.sizeof(float) )
    if cmat is NULL:
        raise MemoryError();
    for i in range( 16 ):
        (<float*> cmat)[i] = mat.flat[i]
    return cmat[0]

cdef class Mesh:
    cdef sr_mesh* thisptr

    def __cinit__(self, offsets, indicies):
        self.thisptr = _np_offset_indicies_to_mesh(offsets, indicies)

    def __dealloc__(self):
        if self.thisptr is not NULL:
            sr_delete_mesh( self.thisptr )

    cdef sr_mesh* get_pointer(self):
        return self.thisptr

def mesh_from_trimesh(t_mesh):
    offsets = np.array([[0, v[0], v[1], v[2]] for v in t_mesh.vertices])
    indicies = np.array([i for face in t_mesh.faces for i in face]) # This is the pyhton way of squashing a list??
    
    return Mesh(offsets, indicies)

cdef class Object:
    cdef sr_object* thisptr

    def __cinit__(self, wl, Mesh mesh, model=IDENTITY):
        # Break all the args down to appropriate structs
        cdef sr_obj_wl* wl_ptr = _wl_to_obj_wl_ptr(wl); 
        cdef mat4 model_mat4 = <mat4> _np_to_mat4(model);
        cdef sr_mesh* mesh_ptr = mesh.get_pointer();
        
        cdef sr_object* obj = <sr_object*> malloc( sizeof(sr_object) )
        if obj is NULL:
            raise MemoryError
        if sr_object_init(obj, wl_ptr, mesh_ptr, model_mat4):
            raise Exception("Failed to init Object")
        self.thisptr = obj

        # These are all copied in so we can destroy these.
        free(wl_ptr)
    def __dealloc__(self):
        if self.thisptr is not NULL:
            sr_object_delete( self.thisptr )

    def draw(self):
        if self.thisptr is not NULL:
            sr_object_draw(self.thisptr);

    @property
    def wl(self):
        raise Exception("Do not get wl from draw Object")

    @wl.setter
    def wl(self, wl):
        cdef sr_obj_wl* wl_ptr = _wl_to_obj_wl_ptr(wl)
        sr_object_update_wl(self.thisptr, wl_ptr)
        free(wl_ptr)

# INIT
def init():
    global camera
    global BOX_MESH
    global SPHERE_MESH
    camera = _Camera()

    v_shader = open('sr_phys/gl_draw/shaders/v_shader.vert.glsl', 'r')
    f_shader = open('sr_phys/gl_draw/shaders/f_shader.frag.glsl', 'r')
    sr_draw_init( v_shader.read().encode(), f_shader.read().encode(), '' )

    camera_set_c(c);

    BOX_MESH = mesh_from_trimesh( trimesh.primitives.Box(
        extents=[1,1,1],
        transform=[
        [1,0,0,0.5],
        [0,1,0,0.5],
        [0,0,1,0.5],
        [0,0,0,1]
            ]
        ).to_mesh() ) 

    SPHERE_MESH = mesh_from_trimesh( trimesh.primitives.Sphere(
        radius=1
        ).to_mesh() ) 
    
    return;

def clear():
    sr_clear()

# Drawing
def draw_mesh(mesh, screen, game_camera, col='red'):
    global BOX_MESH
    global camera

    camera.pos = game_camera.lc().origin.vec.vec[1:4];
    camera.time = game_camera.time;
    camera.lorentz_matrix = lorentz_matrix( game_camera.vel )

    if '_render' in vars(mesh):
        if mesh._render.type == 'WL_BOX':
            if not mesh._render.obj:
                mesh._render.obj = Object(mesh._render.wl,
                                          BOX_MESH,
                                          mesh._render.model
                                          )

            if mesh._render.wl.dirty:
                mesh._render.obj.wl = mesh._render.wl
                mesh._render.wl.dirty = False;
                
        mesh._render.obj.draw()
        return;

    for wl in mesh.wls:
        draw_wl(wl, screen, game_camera)


def draw_wl(wl, screen, game_camera):
    global SPHERE_MESH
    global camera

    camera.pos = game_camera.lc().origin.vec.vec[1:4];
    camera.time = game_camera.time;
    camera.lorentz_matrix = lorentz_matrix( game_camera.vel )

    if '_render' in vars(wl):
        if wl._render.type == 'WL':
            if not wl._render.obj:
                wl._render.obj = Object(wl,
                                          SPHERE_MESH,
                                          wl._render.model
                                          )

            if wl.dirty:
                wl._render.obj.wl = wl
                wl.dirty = False;
                
        wl._render.obj.draw()
        return;

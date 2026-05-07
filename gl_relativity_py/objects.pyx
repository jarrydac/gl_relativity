import cython
import copy
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

import numpy as np
cimport numpy as cnp
import trimesh

BOX_MESH = None;
SPHERE_MESH = None;

IDENTITY= np.array([
    [1, 0, 0, 0],
    [0, 1, 0, 0],
    [0, 0, 1, 0],
    [0, 0, 0, 1]
    ])


def init():
    global BOX_MESH
    global SPHERE_MESH

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

def close():
    for obj in Object.objects:
        del obj
    for mesh in Mesh.meshes:
        del mesh
        
def sphere_mesh():
    return SPHERE_MESH

def box_mesh():
    return BOX_MESH

# An (immutable) mesh of verticies and indicies
cdef class Mesh:
    meshes = []

    cdef sr_mesh* thisptr

    def __cinit__(self, offsets, normals, indicies):
        cdef int offsets_len = len(offsets)
        cdef int indicies_len = len(indicies)

        cdef sr_mesh_vert* offset_array = <sr_mesh_vert*> malloc( sizeof(sr_mesh_vert)*offsets_len)
        cdef int* index_array = <int*> malloc( sizeof(int)*indicies_len)

        self.thisptr = <sr_mesh*> malloc( sizeof(sr_mesh) )
        
        if NULL in (self.thisptr, offset_array, index_array):
            raise MemoryError()

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
        
        Mesh.meshes.append(self)

    def __dealloc__(self):
        if self.thisptr is not NULL:
            sr_delete_mesh( self.thisptr )
            free( self.thisptr )
            self.thisptr = NULL

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
    objects = []

    cdef sr_object* thisptr
    cdef public wl

    def __cinit__(self, wl, Mesh mesh, model=IDENTITY, color=np.array([1.0,500.0])):
        if(mesh == None):
            raise ValueError("Attempted to create object with no mesh!")

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
        
        Object.objects.append(self)

    def __dealloc__(self):
        if self.thisptr is not NULL:
            sr_object_delete( self.thisptr )
            free( self.thisptr )
            self.thisptr = NULL

    def _update_wl(self):
        cdef sr_obj_wl* wl_ptr = _wl_to_obj_wl_ptr(self.wl)
        sr_object_update_wl(self.thisptr, wl_ptr)
        free(wl_ptr)

    def draw(self):
        if self.wl.dirty:
            self._update_wl()

        if self.thisptr is not NULL:
            sr_object_draw(self.thisptr)

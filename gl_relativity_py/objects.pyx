import cython
import copy
from libc.stdlib cimport free
from libc.string cimport memcpy

import numpy as np
cimport numpy as cnp
import trimesh

from .util import MAT4_IDENTITY
from .util_cy cimport safe_malloc, GLResource

# is the module init
_ISINIT = False
_Mesh_preload = []
_Object_preload = []

# Collection of basic primitive meshes
primitives = {
    "SPHERE": None,
    "BOX": None
}

def init():
    global _ISINIT
    global _Mesh_preload
    global _Object_preload

    # Create primitive meshes
    primitives["BOX"] = Mesh.from_trimesh( trimesh.primitives.Box(
        extents=[1,1,1],
        transform=[
        [1,0,0,0.5],
        [0,1,0,0.5],
        [0,0,1,0.5],
        [0,0,0,1]
            ]
        ).to_mesh() ) 

    primitives["SPHERE"] = Mesh.from_trimesh( trimesh.primitives.Sphere(
        radius=1
        ).to_mesh() ) 
    
    # Pass on init
    for mesh in _Mesh_preload:
        mesh._gl_init()
    # Ensure meshes are loaded before objects
    for obj in _Object_preload:
        obj._gl_init()
    
    del _Mesh_preload
    del _Object_preload
    _ISINIT = True

def close():
    global _ISINIT
    _ISINIT = False

class Worldline:
    """Basic worldline"""
    def __init__(self, events):
        # Update the worldline
        self.dirty = True

        self._events = [np.array(event[0:4]).copy() for event in events]
        self._events.sort(key = lambda ev: ev[0])

cdef class Mesh(GLResource):
    """ An (immutable) mesh of verticies and indicies """
    cdef sr_mesh* thisptr
    cdef dict __dict__
    
    def __init__(self, offsets, normals, indicies):
        global _ISINIT
        global _Mesh_preload

        super().__init__()

        self._offsets = offsets
        self._normals = normals
        self._indicies = indicies
        
        if _ISINIT:
            # If the module is init, we expect an opengl context
            self._gl_init()
        else:
            _Mesh_preload.append(self)

    def _gl_init(self):
        offsets = self._offsets
        normals = self._normals
        indicies = self._indicies

        cdef int offsets_len = len(offsets)
        cdef int indicies_len = len(indicies)

        cdef sr_mesh_vert* offset_array = <sr_mesh_vert*> safe_malloc( sizeof(sr_mesh_vert)*offsets_len )
        cdef int* index_array = <int*> safe_malloc( sizeof(int)*indicies_len )
        self.thisptr = <sr_mesh*> safe_malloc( sizeof(sr_mesh) )

        # Read in vertex data
        for i in range( offsets_len ):
            # Space time offsets in positions 1-4.
            for j in range(4):
                offset_array[i].position[j] = offsets[i][j]
            # Normals in positions 4-7
            for j in range(3):
                offset_array[i].position[j+4] = normals[i][j]

        # Read in the indicies
        for i in range( indicies_len ):
            index_array[i] = indicies[i]

        sr_init_mesh(self.thisptr, 
                     index_array, indicies_len,
                     offset_array, offsets_len
                     )
        
        del self._offsets
        del self._normals
        del self._indicies
        

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
    wl_len = len(wl._events)
    if wl_len > 1023:    
        raise ValueError(f"WL too long! {wl_len}")

    cdef sr_obj_wl* wl_ptr = <sr_obj_wl*> safe_malloc( sizeof(sr_obj_wl) ) # note in objects.h array is fixed size so it is of course already allocated now.
    cdef cnp.ndarray contiguous_events = np.ascontiguousarray(wl._events, dtype='f')

    wl_ptr.length = wl_len
    memcpy(wl_ptr.events, contiguous_events.data, wl_ptr.length*sizeof(vec4))

    return wl_ptr

cdef class Object(GLResource):
    """A drawable object, has a worldline, and associated mesh and a model matrix"""
    cdef sr_object* thisptr
    cdef dict __dict__
    cdef public wl

    def __init__(self, *args):
        super().__init__()
        if(mesh == None):
            raise ValueError("Attempted to create object with no mesh!")
        self._wl = wl
        self._mesh = mesh
        self._model = model

    def _gl_init(self):
        wl = self._wl
        mesh = self._mesh
        model = self._model

        # Break all the args down to appropriate structs
        cdef sr_obj_wl* wl_ptr = _wl_to_obj_wl_ptr(wl); 
        cdef sr_mesh* mesh_ptr = mesh.get_pointer();
        cdef mat4 model_mat4 = np.ascontiguousarray(model, dtype="f")
        cdef vec2 color_vec2 = np.ascontiguousarray(color, dtype="f")
        
        cdef sr_object* obj = <sr_object*> safe_malloc( sizeof(sr_object) )

        if sr_object_init(obj, wl_ptr, mesh_ptr, model_mat4, color_vec2):
            raise Exception("Failed to init Object")

        self.thisptr = obj

        # These are all copied in so we can destroy these.
        free(wl_ptr)
        self.wl = wl

        del self._wl
        del self._mesh
        del self._model

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

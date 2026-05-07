import cython
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

import math
import numpy as np
cimport numpy as cnp

from .util_cy cimport GLResource

def init():
    pass

def close():
    pass

# Lights
cdef class Light(GLResource):
    cdef sr_light* thisptr
    cdef sr_light_discrete_spectrum* disc_spec
    cdef sr_light_continuous_spectrum* cont_spec

    def __init__(self, *args):
        super().__init__()

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
            self.cont_spec = <sr_light_continuous_spectrum*> \
                        malloc( sizeof(sr_light_continuous_spectrum) )
            if self.cont_spec is NULL:
                raise MemoryError

            for i in range(100):
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
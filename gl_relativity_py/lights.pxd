from .types cimport *


cdef extern from '../include/lights.h':
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
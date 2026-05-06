from .types cimport *

cdef extern from '../include/camera.h':
    void camera_init();

    void camera_get_pos( vec3 pos );
    void camera_set_pos( vec3 pos );
    
    void camera_get_vel( vec3 velocity );
    void camera_set_vel( const vec3 velocity );

    void camera_get_angle( float* pitch, float* yaw);
    void camera_set_angle( float pitch, float yaw );
    
    float camera_get_time();
    void camera_set_time( float time );

    float camera_get_inv_c();
    void camera_set_inv_c( float );

    void camera_set_lorentz( mat4 );
    void camera_get_lorentz( mat4 );
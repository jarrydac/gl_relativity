/**
 * Fly-camera view matrix.
 */ 

#ifndef SR_DRAW_CAMERA
#define SR_DRAW_CAMERA

#include "include/cglm/cglm.h"

/**
 * Setup initial camera values.
 */
void camera_init(void);

// Camera time (usually duration of scene).
float camera_get_time(void);
void camera_set_time( float time );

void camera_get_pos( vec3 position );
void camera_set_pos( const vec3 position );

void camera_get_angle( float* pitch, float* yaw);
void camera_set_angle( float pitch, float yaw );

void camera_look_direction(float pitch, float yaw, vec3 direction);
void camera_view_matrix( mat4 view );

#endif

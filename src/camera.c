#include "../include/camera.h"

static struct  {
    float inv_c;
    float time;
    vec3 position;
    vec3 velocity;
    float pitch;
    float yaw;
    vec3 up;
    mat4 lorentz;
} camera;

void camera_init(void){
    camera.time = 0.0f;
    glm_vec3_copy( GLM_YUP, camera.up);
    glm_vec3_copy( GLM_VEC3_ZERO, camera.position);
    glm_vec3_copy( GLM_VEC3_ZERO, camera.velocity);
    glm_mat4_copy( GLM_MAT4_IDENTITY, camera.lorentz );
    camera.pitch = glm_rad( 0.0f );
    camera.yaw = glm_rad( -90.0f );
}

void camera_get_pos( vec3 pos ){
    glm_vec3_copy( camera.position, pos );
}

void camera_set_pos( const vec3 pos ){
    glm_vec3_copy( (float*) pos, camera.position );
}

void camera_get_vel( vec3 vel ){
    glm_vec3_copy( camera.velocity, vel );
}

void camera_set_vel( const vec3 vel ){
    glm_vec3_copy( (float*) vel, camera.velocity );
}

void camera_get_angle( float* pitch, float* yaw ){
    *pitch = camera.pitch;
    *yaw = camera.yaw;
}

void camera_set_angle( float pitch, float yaw ){
    camera.pitch = pitch;
    camera.yaw = yaw;
}

void camera_set_time( float t ){
    camera.time = t;
}

float camera_get_time(void){
    return camera.time;
}

void camera_set_inv_c( float inv_c ){
    camera.inv_c = inv_c;
}

float camera_get_inv_c(void){
    return camera.inv_c;
}

void camera_set_lorentz( const mat4 lorentz ){
    glm_mat4_copy( (vec4*) lorentz, camera.lorentz ); 
}

void camera_get_lorentz( mat4 lorentz ){
    glm_mat4_copy( camera.lorentz, lorentz ); 
}

void camera_look_direction(float pitch, float yaw, vec3 direction){
    if(pitch > glm_rad(89.0f) ) pitch = glm_rad(89.0f); // Protect for being paralell with camera.up.
    if(pitch < glm_rad(-89.0f) ) pitch = glm_rad(-89.0f);
    direction[0] = cos(yaw) * cos(pitch);
    direction[1] = sin(pitch);
    direction[2] = sin(yaw) * cos(pitch);
    glm_normalize(direction);
}

void camera_view_matrix( mat4 view ){
    vec3 camera_dir;
    camera_look_direction(camera.pitch, camera.yaw, camera_dir);
    glm_look(camera.position, camera_dir, camera.up, view);
}

void camera_close(void);
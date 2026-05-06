import numpy as np

# Speed of light
inv_c = 1/30.0

def init():
    camera_init()

def close():
    pass

def lorentz_matrix(vel):
    vel_hat = np.linalg.norm( vel )
    gamma = 1/(np.sqrt(1-(vel_hat**2*inv_c**2)))
    gamma_f = (gamma**2)/(1+gamma)

    # Wikipeda... Lorentz Transforms
    beta_x = vel[0]*inv_c
    beta_y = vel[1]*inv_c
    beta_z = vel[2]*inv_c

    matrix = [
            [ gamma, -gamma*beta_x, -gamma*beta_y, -gamma*beta_z ],
            [ -gamma*beta_x, 1 + (gamma_f*beta_x**2), gamma_f*beta_x*beta_y, gamma_f*beta_x*beta_z ],
            [ -gamma*beta_y, gamma_f*beta_x*beta_y, 1 + (gamma_f*beta_y**2), gamma_f*beta_y*beta_z ],
            [ -gamma*beta_z, gamma_f*beta_x*beta_z, gamma_f*beta_y*beta_z, 1 + (gamma_f*beta_z**2) ]
            ]

    return np.array(matrix, dtype='f')

def get_pos(self):
    cdef vec3 pos
    camera_get_pos( pos )
    return pos

def get_vel(self):
    cdef vec3 vel
    camera_get_vel( vel )
    return self.vel

def get_angle( self ):
    cdef float pitch 
    cdef float yaw
    camera_get_angle( &pitch, &yaw )
    return (pitch, yaw)

def get_time( self ):
    return camera_get_time()

def get_lorentz_matrix( self ):
    cdef mat4 arr; 
    camera_get_lorentz( arr )
    return arr

def get_inv_c():
    return camera_get_inv_c()

def set_pos(  vec3 pos ):
    camera_set_pos( pos )

def set_angle(  angle ):
    camera_set_angle( angle[0], angle[1] )

def set_time(  time ):
    camera_set_time(time)

def set_vel( vec3 vel):
    camera_set_vel( vel )

    lorentz_transform = lorentz_matrix(vel)
    cdef mat4 arr = np.ascontiguousarray(lorentz_transform, dtype='f')
    camera_set_lorentz( <mat4> arr )
    
def set_inv_c(inv_c):
    camera_set_inv_c(inv_c)
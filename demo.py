#!/bin/env python3

#
# Demo of gl_relativty.
#
# The camera can be given velocity with WASD, SHIFT and SPACE.
# The camera can be aimed with IJKL.
#
# A model can be supplied as and argument at the command line.
#
# Jarrydac. 2026-04-16
#
import gl_relativity_py
from gl_relativity_py import draw, camera

from gl_relativity_py.lights import Light
from gl_relativity_py.objects import Mesh, Object, Worldline, primitives 
from gl_relativity_py.util import MAT4_IDENTITY

import pygame
import numpy as np

import sys
import math

# CONSTANTS
SIZE = (800,800)
PLAYER_Z = 50
TIME = 10

pos = np.array([0.0, 0.0, PLAYER_Z])
vel = np.array([0.0, 0.0, 0.0])
angle = np.array([0.0, -math.pi/2 ])
time = 0

# Main 
pygame.init()
pygame.display.gl_set_attribute(pygame.GL_CONTEXT_MAJOR_VERSION, 4)
pygame.display.gl_set_attribute(pygame.GL_CONTEXT_MINOR_VERSION, 3)
screen = pygame.display.set_mode(SIZE, pygame.OPENGL | pygame.DOUBLEBUF)

gl_relativity_py.init()
camera.set_inv_c( 1.0/15.0 )

# Black-body spectrum, according to Planck's Equation.
bk = (3e8*6.626e-34)/1.38e-23
def planck_func(T, scale):
    def planck(lam):
        ratio = bk/(lam*T)
        if ratio > 700:
            return 0

        val = ( lam**5 * math.expm1(ratio) )**-1 / scale
        return val
    
    return planck

light3 = Light( np.array([150,15,100]), planck_func(4000, 5e30), None )
light4 = Light( np.array([10,15,50]), planck_func(15000, 1e34), None)
light5 = Light( np.array([0,10,0]), None, np.array( [[500,0.2]] ) )

def track(t):
    speed = 2*math.pi/10
    mag = 15
    return [mag*math.cos(t*speed),0,mag*math.sin(t*speed)]

def wl_orbit(t_offset):
    events = []
    for t in np.linspace(-TIME,TIME,1000):
        events.append([ t, *track(t-t_offset) ])
    wl = Worldline( np.array( events ) )
    return wl

# Read mesh from command line, or use default sphere.
if len(sys.argv) == 1 or sys.argv[1] == "ball":
    mesh = primitives["SPHERE"]
else:
    mesh = Mesh.from_file(sys.argv[1])
    
sr_objects = []

for i in range(30):
    wl = wl_orbit(i/3)
    # Create objects, to scale (identity model matrix).
    sr_objects.append( Object( wl, mesh, MAT4_IDENTITY) )

sr_objects.append( Object( Worldline( np.array([[-TIME,0.1,0.0,0.0],[TIME,0.0,0.0,0.0]]) ), mesh, MAT4_IDENTITY))  

clock = pygame.time.Clock()
running = True
dt = 0

def poll_keyboard():
    keys = pygame.key.get_pressed()
    if keys[pygame.K_a]:
        vel[0] += 0.1
    if keys[pygame.K_d]:
        vel[0] += -0.1
    if keys[pygame.K_s]:
        vel[2] += 0.1
    if keys[pygame.K_w]:
        vel[2] += -0.1
    if keys[pygame.K_SPACE]:
        vel[1] += -0.1
    if keys[pygame.K_LSHIFT]:
        vel[1] += 0.1

    if keys[pygame.K_i]:
        angle[0] += 0.01
    if keys[pygame.K_k]:
        angle[0] -= 0.01
    if keys[pygame.K_j]:
        angle[1] -= 0.01
    if keys[pygame.K_l]:
        angle[1] += 0.01

# MAIN LOOP
while running:
    # Handle input/logic
    poll_keyboard()

    # Update camera
    camera.set_pos( pos )
    camera.set_vel( vel )
    camera.set_angle( angle )
    camera.set_time( time % TIME )

    # Clear the screen
    draw.clear(0.0, 0.0, 0.0)
    
    # Draw objects
    for sr_object in sr_objects:
        sr_object.draw()
        
    # Flip display
    pygame.display.flip()

    # Update clock
    dt = clock.tick(30) / 1000
    time += dt
    
    # Handle close window
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
# Cleanup
gl_relativity_py.close()
pygame.quit()
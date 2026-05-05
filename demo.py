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

import gl_relativity as draw

from enum import Enum

import pygame
import numpy as np
import trimesh

import sys
import math

# CONSTANTS
SIZE = (800,800)
PLAYER_Z = 50
TIME = 10

class Player:
    def __init__(self):
        self.pos = np.array([0.0, 0.0, PLAYER_Z])
        self.vel = np.array([0.0, 0.0, 0.0])
        self.angle = np.array([0.0, -math.pi/2 ])

    def update(self, dt):
        pass

class Worldline:
    def __init__(self, events):
        # Update the worldline
        self.dirty = True

        self._events = [np.array(event[0:4]).copy() for event in events]
        self._events.sort(key = lambda ev: ev[0])

draw.inv_c = 1.0/15.0
#draw.inv_c = 0

# Main 
pygame.init()
pygame.display.gl_set_attribute(pygame.GL_CONTEXT_MAJOR_VERSION, 4)
pygame.display.gl_set_attribute(pygame.GL_CONTEXT_MINOR_VERSION, 3)
screen = pygame.display.set_mode(SIZE, pygame.OPENGL | pygame.DOUBLEBUF)
draw.init()

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

light3 = draw.Light( np.array([150,15,100]), planck_func(4000, 5e30), None )
light4 = draw.Light( np.array([10,15,50]), planck_func(15000, 1e34), None)
light5 = draw.Light( np.array([0,10,0]), None, np.array( [[500,0.2]] ) )

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
    mesh = draw.SPHERE_MESH
else:
    mesh = draw.Mesh.from_file(sys.argv[1])
    
sr_objects = []

for i in range(30):
    wl = wl_orbit(i/3)
    # Create objects, to scale (identity model matrix).
    sr_objects.append( draw.Object( wl, mesh, np.array([
        [1,0,0,0],
        [0,1,0,0],
        [0,0,1,0],
        [0,0,0,1]
        ]))
    )

sr_objects.append( draw.Object( Worldline( np.array([[-TIME,0.1,0.0,0.0],[TIME,0.0,0.0,0.0]]) ), mesh, np.array([
    [1,0,0,0],
    [0,1,0,0],
    [0,0,1,0],
    [0,0,0,1]
    ]))
) 

player = Player()

clock = pygame.time.Clock()
running = True
dt = 0
time = 0

def poll_keyboard():
    keys = pygame.key.get_pressed()
    if keys[pygame.K_a]:
        player.vel[0] += 0.1
    if keys[pygame.K_d]:
        player.vel[0] += -0.1
    if keys[pygame.K_s]:
        player.vel[2] += 0.1
    if keys[pygame.K_w]:
        player.vel[2] += -0.1
    if keys[pygame.K_SPACE]:
        player.vel[1] += -0.1
    if keys[pygame.K_LSHIFT]:
        player.vel[1] += 0.1

    if keys[pygame.K_i]:
        player.angle[0] += 0.01
    if keys[pygame.K_k]:
        player.angle[0] -= 0.01
    if keys[pygame.K_j]:
        player.angle[1] -= 0.01
    if keys[pygame.K_l]:
        player.angle[1] += 0.01

while running:
    poll_keyboard()
    player.update(dt)

    # Call the appropriate (visible) draw calls
    draw.clear(0.0, 0.0, 0.0)

    # Update camera
    draw.camera.pos = player.pos 
    draw.camera.vel = player.vel 
    draw.camera.angle = player.angle
    draw.camera.time = time % TIME
    
    # Drawing
    for sr_object in sr_objects:
        sr_object.draw()
    pygame.display.flip()

    # Update clock
    dt = clock.tick(30) / 1000
    time += dt
    
    # Crash out
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

draw.close()
pygame.quit()
sys.exit()

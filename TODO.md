# TODO

## General

- TODO: Proper deallocation!! Of everthing!!  
- TODO: Lots of unused cruft in the fragment shader.  

## Geometry

To draw an object, first load a Mesh and then initialise an Object with a Worldline and model matrix. 
The Worldline corresponds to the position of the Mesh origin. The .dirty flag should be set on the Worldline
if the worldline is updated, in order to write the new worldline to the GPU. (This flag should be set appropriately in np-phys)
The .draw() method draws the object using the current global camera setup.

- TODO: The C Worldline has a max length, which should be checked in the cython code.  
- TODO: The OpenGL code only allocates Worldlines sequentially up to a limit - the memory allocation should be smarter.  

The Worldline for each object is written into one row of a 2D GL_Texture, and the number of points is written in another 
1D texture. The wl_id is set as a uniform before the mesh is drawn. The vertex shader offsets the origin wl by the vertex position and
determines the visible point of the wl (where the space-time interval is 0, and t<0).

## Lighting

The initial lighting model is based off the Phong lighting model, as described in this tutorial:
https://learnopengl.com/Lighting/Basic-Lighting.

In order to make the calculation of doppler shift tractable all lights are stationary. (It seems feasible to implements that can be switched on and off). 

The color and intensity of lights are defined by two intensity spectra: a continuous part, defined from 0 to Infinity, and a discrete set of intensities at monochrome frequencies.

Two doppler shifts are needed. For a given frequency at the camera, find the frequency reflected in the object frame. (Here the reflectivity of the material at the frequency in the object frame would be applied). Then the shift from the object frequency to the light's emission-frequency is calculated to get the appropriate intensity of the light.

CIE data is used to calculate the XYZ values, which are transformed to RGB.

- TODO: Materials (reflectivity).  
- TODO: Use x' = x/(x+1) and x = x'/(1-x') mapping to store spectra in finite range, rather than exp and log.  
- TODO: toggleable lights?  
- TODO: Store 1/c instead of c, so we can set 1/c = 0 to ignore relativistic effects.  
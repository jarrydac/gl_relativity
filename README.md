# gl_relativity

**gl_relativity** is a package for drawing scenes with special-relativistic effects.

## Usage

- Objects move along worldlines, which are given in the lab-frame coordinates.
- Stationary lights are placed in the scene with lab-frame coordinates.
- The camera is placed in the lab-frame, with some velocity relative to the lab-frame.

See `demo.sh` and `demo.py` for a basic application, using pygame.

## Effects

Per vertex:
- Lorentz transformation
- Time of flight effects (e.g. Terrell rotation)

Per fragment:
- Doppler-shift

## Building 

Install:
- [trimesh](https://trimesh.org/)
- [numpy](https://numpy.org/)
- [cython](https://cython.org/)
- [setuptools](https://pypi.org/project/setuptools/)

1. Make the C library using the Makefile. (This will download [cglm](https://github.com/recp/cglm).)
2. Build the cython module using setup.py (i.e. `python setup.py build_ext --inplace`)
3. Copy the created `.so`, `shaders/` and `CIE_xyz_1931_2deg.csv` file alongside python project and `import gl_relativity_py`.

## How-to

1. Set the speed of light (the inverse speed of light is set, i.e. setting 0 is an infinite speed of light).
2. Setup the lighting, load meshes and create object.
3. Update camera position, velocity, and current time.
4. Clear the screen with `gl_clear()`
5. To draw an object, set the worldline and call the draw function.
6. Flip buffers

## Demo

Here is a link to the demo video: [https://www.youtube.com/watch?v=PWjvE9ucgI0](https://www.youtube.com/watch?v=PWjvE9ucgI0)
[ ![](https://img.youtube.com/vi/PWjvE9ucgI0/sddefault.jpg) ](https://www.youtube.com/watch?v=PWjvE9ucgI0)

## Function 

The worldline sets the position of the mesh over time. The .draw() method draws the object using the current global camera setup.

The worldline for each object is written into a GL_Texture. In python the .dirty flag should be set on the worldline if the worldline is updated, in order to write the new worldline to the GPU. The worldline row is set as a uniform before the mesh is drawn. The vertex shader offsets the origin wl by the vertex position and determines the visible point of the wl (where the space-time interval is 0, and t<0).

In order to make the calculation of doppler shift tractable all lights are stationary. (It seems feasible to implements that can be switched on and off). The color and intensity of lights are defined by two intensity spectra: a continuous part, and a discrete set of monochrome wavelengths.

For reflective lighting two doppler shifts are needed. For a given frequency at the camera, find the frequency reflected in the object frame. (Here the reflectivity of the material at the frequency in the object frame would be applied). Then the shift from the object frequency to the light's emission-frequency is calculated to get the appropriate intensity of the light.

CIE data is used to calculate the XYZ values, which are transformed to RGB.

## Caution

Very much experimental. This is my first project using OpenGL and Cython. Expect egregious errors. 


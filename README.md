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

## Caution

Very much experimental. This is my first project using OpenGL and Cython. Expect egregious errors. 


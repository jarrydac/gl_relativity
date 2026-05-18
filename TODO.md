# gl_relativity
Draw scenes with special relativistic effects.

### General
- [x] Store inv_c, with inv_c = 0 to disable relativistic effects
- [ ] Cleanup `wl_vert_shader.glsl`
- [ ] Shift essential functionality from python to C
    - [ ] Write a C demo
- [ ] Remove constants: `nearZ`, `farZ`, `fov`, and ect.
- [ ] Rationalise `shader.c`
- [ ] Documentation

### Geometry
- [x] Infinite worldlines
- [ ] Proper cut of of finite worldlines
- [ ] Smarter measurement of worldline texture memory
    - [ ] Precomp which part of worldline to send to GPU? Streaming? 

### Lighting
- [ ] Use x' = x/(x+1) and x = x'/(1-x') mapping to store spectra
- [ ] Linear combinations of different emissions rows
- [ ] More efficient continuous lighting
- [ ] Different lighting setups for different objects
- [ ] Toggleable lights  
- [ ] More light types, see [learnopengl.com/Lighting/Light-casters](https://learnopengl.com/Lighting/Light-casters)

### Materials
- [ ] Implement per-object materials
- [ ] Implement textures, multiple materials per object, like a gif palette of materials

### Packaging
- [ ] Pull CIE data and shaders into package
- [ ] Remove `LD_LIBRARY_PATH` requirement 
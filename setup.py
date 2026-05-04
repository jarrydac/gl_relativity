from setuptools import Extension, setup
from Cython.Build import cythonize

import numpy as np

extensions = [
    Extension("gl_relativity", ["draw.pyx"],
        include_dirs=["include",np.get_include(),"lib/include"],
	    libraries=["gl_relativity"],
	    library_dirs=["./"]	
    ),
]
setup(
    name="Cython modules for gl_relativity",
    ext_modules=cythonize(extensions),
)


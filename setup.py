from setuptools import Extension, setup
from Cython.Build import cythonize

extensions = [
    Extension("gl_relativity", ["draw.pyx"],
        include_dirs=["include","lib/include"],
	libraries=["gl_relativity"],
	library_dirs=["./"]	
    ),
]
setup(
    name="Cython modules for gl_relativity",
    ext_modules=cythonize(extensions),
)


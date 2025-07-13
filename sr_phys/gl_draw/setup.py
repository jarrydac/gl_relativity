from setuptools import Extension, setup
from Cython.Build import cythonize

extensions = [
    Extension("sr_draw", ["draw.pyx"],
        include_dirs=["include","lib/include"],
	libraries=["sr_draw"],
	library_dirs=["./"]	
    ),
]
setup(
    name="Cython modules for gl_draw",
    ext_modules=cythonize(extensions),
)


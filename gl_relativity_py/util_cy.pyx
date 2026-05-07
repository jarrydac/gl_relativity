from libc.stdlib cimport malloc

cdef void* safe_malloc( int size ):
    """Create a pointer and perform the null check"""
    cdef void* ptr = malloc( size )
    if ptr is NULL:
        raise MemoryError()
    return ptr


cdef class GLResource:
    """OpenGL resources need to be freed before the context is destroyed."""
    _refs = []
    def __init__(self):
        GLResource._refs.append(self)

    @staticmethod
    def close():
        for ref in GLResource._refs:
            del ref


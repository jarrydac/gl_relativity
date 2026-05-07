from . import draw 
from . import camera 
from . import lights 
from . import objects 

from .util_cy import GLResource

def init():
    draw.init()
    camera.init()
    lights.init()
    objects.init()

    
def close():
    GLResource.close()

    objects.close()
    lights.close()
    camera.close()
    draw.close()


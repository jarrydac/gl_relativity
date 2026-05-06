from . import draw 
from . import camera 
from . import lights 
from . import objects 

def init():
    draw.init()
    camera.init()
    lights.init()
    objects.init()

    
def close():
    objects.close()
    lights.close()
    camera.close()
    draw.close()


from phue import Bridge
import time
b = Bridge('IP_Of_Bridge_Here')
b.connect()
b.get_api()

b.set_light(2, 'on', False)
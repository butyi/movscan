import time
import picamera

camera = picamera.PiCamera()
try:
    camera.resolution = (640, 480)
    camera.start_preview()
    time.sleep(10000)
    camera.stop_preview()
finally:
    camera.close()

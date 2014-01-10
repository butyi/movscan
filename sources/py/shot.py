import picamera
import time

with picamera.PiCamera() as camera:
    try:
        camera.resolution = (640, 480)
        camera.start_preview()
        time.sleep(2)
        camera.capture('/home/pi/pics/shot.jpg')
        camera.stop_preview()
    finally:
        camera.close()

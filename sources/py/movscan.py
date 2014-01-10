import picamera
import time
import os
import RPi.GPIO as GPIO ## Import GPIO library

with picamera.PiCamera() as camera:
    os.chdir('/home/pi/pics')
    GPIO.setmode(GPIO.BOARD) ## Use board pin numbering
    GPIO.setup(11, GPIO.IN) ## Setup GPIO Pin 11 to IN
    n = 0
    camera.start_preview()
    camera.resolution = 2592,1944
    #camera.crop=0.295,0.365,0.5,0.5
    camera.crop=0.1,0.24,0.48,0.48
    camera.rotation=180
    camera.resolution = 800,600
    preview_fullscreen = True
    time.sleep(3)
    while True:
        GPIO.wait_for_edge(11, GPIO.FALLING)
        #GPIO.wait_for_edge(11, GPIO.RISING)
        camera.capture_sequence((
                'image%05d.jpg' % n
                for p in range(1)
                ), use_video_port=True)
        print "image %d" % n
        n = n + 1
    camera.stop_preview()
    camera.close()


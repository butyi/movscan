#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright: Bencsik János <copyright@butyi.hu>
# License : WTFPL v2 <http://www.wtfpl.net/txt/copying/>

import picamera
import time
import os
import RPi.GPIO as GPIO ## Import GPIO library

# Create object
with picamera.PiCamera() as camera:

    # Change folder where I want to save images
    os.chdir('/home/pi/pics')
    
    # Board I/O init
    GPIO.setmode(GPIO.BOARD) # Use board pin numbering
    GPIO.setup(11, GPIO.IN) # Setup GPIO Pin 11 to shot input
    GPIO.setup(7, GPIO.IN) # Setup GPIO Pin 7 to watchdog input
    
    # Image counter
    n = 0 
    
    # Switch on camera 
    # (following setting needs active camera)
    width = 800 # Max resolution: 2592 x 1944
    camera.resolution = width,(width*3/4) # Image size (digit zoom, not resize!)
    camera.start_preview() 

    # Adjust camera for my environment 
    camera.crop=0.43,0.26,0.5,0.5 # Crop active CCD part
    camera.vflip = True # Mirroring is needed due to optic
    camera.resolution = width,(width*3/4) # Image size (digit zoom, not resize!)
    preview_fullscreen = True # To see same what will be saved
    time.sleep(3) # Wait to camera auto settings

    # Edge detect variables for shoot detection 
    # (GPIO.wait_for_edge is not proper, because during waiting edge
    #  watchdog inpunt must be monitorred)
    pin11state = GPIO.HIGH # Due to input is active low
    pin11prevst = GPIO.HIGH

    # Main loop
    Loop = True
    while Loop:
        # Wait for shot imput edge
        pin11state = GPIO.input(11)
        if (pin11state == GPIO.LOW && pin11revst == GPIO.HIGH) # Falling edge

<<<<<<< HEAD
            # Take the picture
            camera.capture_sequence((
                'image%05d.jpg' % n # Numberred file name for video creation later on
=======
        # Take the picture
        camera.capture_sequence((
                'image%05d.jpg' % (n+p) # Numberred file name for video creation later on
>>>>>>> 730be0e767ab1eca6b7a5c3fcf9c2ce3a8385c17
                for p in range(1) # One picture is saved only
                ), use_video_port=True) # use_video_port=True speeds up the camera
            print "%d" % n # Inform me about operating
            n = n + 1 # Increase image number

        # Check watchdog input. It is pulse from source reel.
        # It always makes pulse when the reel is moving.
        # When we don't detect pulse for 10...15s, 
        # it is stopped, we can leave the loop by Loop = False.
        #if n>=1:
        #    break

    # Final actions before quit from scrip
    camera.stop_preview() # Switch off the camera
    camera.close()


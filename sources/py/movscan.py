#!/usr/bin/python
# -*- coding: utf-8 -*-
# Copyright: BENCSIK JÃ¡nos <copyright@butyi.hu>
# License : WTFPL v2 <http://www.wtfpl.net/txt/copying/>
# parameter 1: -m : monochrome, -p : show preview

import picamera # Reference: http://picamera.readthedocs.org
import time
import os
import io
import sys
import thread # For safe and fast file save
import RPi.GPIO as GPIO # Import GPIO library


# Define a function for the file save thread
def save_image( stream, filename):
    stream.seek(0) # Rewing in stream
    fo = open(filename, "wb") # Open file
    fo.write(stream.read()) # Write the data
    fo.close() # Close opened file

# Check parameter
if len(sys.argv)<1:
    print "Error! Too few argument."
    exit

# Get arguments
arguments = str(sys.argv)

# Print help
if "-h" in arguments: # If -h (help) parameter is in the arguments, than helpÅ
    print "Usage: sudo python movscan.py [-m|-p|-h]"
    print "-m: monochrome"
    print "-p: show preview"
    print "-h: help"
    exit

# Reserve buffer for images in memory
stream = io.BytesIO()

# Create object
with picamera.PiCamera() as camera:

    # Switch off camera LED to not disturb the image through optic
    ## Be aware when you first use the LED property it will set the 
    ## GPIO library to Broadcom (BCM) mode with GPIO.setmode(GPIO.BCM)
    # Thats why it is set before GPIO Board I/O init
    camera.led = False
     
    # Board I/O init
    GPIO.setmode(GPIO.BOARD) # Use board pin numbering
    GPIO.setup(11, GPIO.IN) # Setup GPIO Pin 11 to shot input
    GPIO.setup(7, GPIO.IN, pull_up_down=GPIO.PUD_UP) # Setup GPIO Pin 7 to watchdog input with activated built-in pull up
    
    # Image counter
    n = 0 
    
    # Switch on camera 
    # (following setting needs active camera)
    width = 800 # Max resolution: 2592 x 1944
    camera.resolution = width,(width*3/4) # Image size (digit zoom, not resize!)
    camera.framerate = 20 # Limit camera speed to have more CPU runtime

    # Start camera
    camera.start_preview() 

    # Adjust camera for my environment 
    camera.crop = 0.25,0.23,0.6,0.6 # Crop active CCD part
    camera.vflip = True # Mirroring is needed due to optic
    camera.preview_fullscreen = False # To be able to resize manually to see command line behind
    camera.preview_window = 600, 10, 640, 480 # It depends on your monitor resolution!
    camera.awb_mode = 'off' # Normal bulb, manual white balance to prevent insable white-balance
    camera.video_stabilization = True # To stabilize mechanical moving os slides
    if "-m" in arguments: # If -m (monochrome) parameter is in the arguments
        camera.color_effects = (128,128) # Black and White image
    time.sleep(1) # Wait to camera auto settings
    if "-p" not in arguments: # If preview is needed
        camera.stop_preview() # Show preview

    # Edge detect variables for shoot detection 
    # (GPIO.wait_for_edge is not proper, because during waiting edge
    #  watchdog inpunt must be monitorred)
    pin11state = GPIO.HIGH # Due to input is active low
    pin11prevst = GPIO.HIGH
    last_wd_edge = time.time() + 10 # Now + 10sec

    # Edge detect variables for watchdog input
    pin7state = GPIO.HIGH # Due to input is active low
    pin7prevst = GPIO.HIGH

    # Main loop
    Loop = True
    while Loop:
        # Wait for shot imput falling edge
        pin11state = GPIO.input(11)
        if (pin11state == GPIO.LOW and pin11prevst == GPIO.HIGH): # Falling edge happened

            # Create file name
            filename = 'image%05d.jpg' % n # Numberred file name for later video creation

            # Measure image time
            captime = time.time();

            # Reserve buffer for images in memory
            stream = io.BytesIO()

            # Take the picture
            camera.capture(
                 stream,
                 format = 'jpeg', # Must be specified in case of stream 
                 use_video_port = True, # If you need rapid capture up to the rate of video frames, set this to True
                 resize = None, # Resize
                 quality = 25, # Defines the quality of the JPEG encoder as an integer ranging from 1 to 100.
                 thumbnail = None # Specifying None disables thumbnail generation.
                )

            # Save image in a different thread to not lose any image due to sporadicaly slow SD card access
            try:
                thread.start_new_thread( save_image, (stream,filename) )
            except:
                print "Error: unable to start thread"

            # Measure image time and warn user if it was longer than 200ms
            captime = time.time() - captime
            warning = " "
            if 0.2 < captime:
                warning = "  " + str(captime) + " s !!!"

            # Inform me about operating
            print filename + warning 

            # Increase image number
            n = n + 1

        # Save shoot pin state for edge detection
        pin11prevst = pin11state

        # Check watchdog input. It is pulse from source reel.
        # It always makes pulse when the reel is moving.
        # When we don't detect pulse for 10...15s, 
        # it is stopped, we can leave the loop by Loop = False.
        pin7state = GPIO.input(7) # Read actual pin state
        if (pin7state <> pin7prevst): # Any edge happened, reel is turning
            last_wd_edge = time.time(); # Save the time of edge

        # Save watchdog pin state for edge detection
        pin7prevst = pin7state

        # Check watchdog time
        elapsed_time = time.time() - last_wd_edge # Calculate elapsed time for last watchdog edge
        if (10 <= n and 30 <= elapsed_time): # if 10 images were saved and elapsed time is more than 30s
            break # Leave the loop, exit from script
        if (n < 10): # reinit wd timer in the begining of movie
           last_wd_edge = time.time() + 10 # Now + 10sec

    # Final actions before quit from scrip
    camera.stop_preview() # Switch off the camera
    camera.close()


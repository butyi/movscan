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

# Config parameters
wd_timeout_in_s = 15

# Statistic variables
thread_create_num = 0
thread_solved_num = 0
max_thread_num = 0

# Define a function for the file save thread
def save_image( stream, filename):    
    global thread_solved_num
    stream.seek(0) # Rewing in stream
    fo = open(filename, "wb") # Open file
    fo.write(stream.read()) # Write the data
    fo.close() # Close opened file
    thread_solved_num = thread_solved_num + 1 # Increase thread number

# Check parameter
if len(sys.argv)<1:
    print "Error! Too few argument."
    exit

# Get arguments
arguments = str(sys.argv)

# Print help
if "-h" in arguments: # If -h (help) parameter is in the arguments, than helpÅ
    print "Usage: sudo python movscan.py [options]"
    print "-n: normal film crop"
    print "-s: super film crop"
    print "-h: help"
    exit

# Statistic variables
filename = "image00000.jpg"
max_thread_num = 0
max_captime = 0
elapsed_time = 0
max_elapsed_time = 0
runtime_shoot = 1
runtime_0 = 1
runtime_1 = 1
runtime_2 = 1
load = 0
captime_int = 0
fps = 0
wd_edge_rising = 1
wd_edge_falling = 1
wd_duty = 50
infotime = time.time()

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
    camera.framerate = 30 # Maximum

    # Start camera
    camera.start_preview() 

    # Adjust camera for my environment 
    if "-s" in arguments: # For super film
        camera.crop = 0.27,0.19,0.6,0.6 # Crop active CCD part
    if "-n" in arguments: # For normal film
        #             0.32
        camera.crop = 0.36,0.23,0.50,0.50 # Crop active CCD part
    camera.vflip = True # Mirroring is needed due to optic
    camera.preview_fullscreen = False # To be able to resize manually to see command line behind
    camera.preview_window = 710, 10, 640, 480 # It depends on your monitor resolution!
    camera.awb_mode = 'off' # Normal bulb, manual white balance to prevent insable white-balance
    camera.video_stabilization = True # To stabilize mechanical moving os slides
    time.sleep(1) # Wait to camera auto settings

    # Edge detect variables for shoot detection 
    # (GPIO.wait_for_edge is not proper, because during waiting edge
    #  watchdog inpunt must be monitorred)
    pin11state = GPIO.HIGH # Due to input is active low
    pin11prevst = GPIO.HIGH
    last_wd_edge = time.time()

    # Edge detect variables for watchdog input
    pin7state = GPIO.HIGH # Due to input is active low
    pin7prevst = GPIO.HIGH

    # Main loop
    Loop = True
    while Loop:
        # Wait for shot imput falling edge
        pin11state = GPIO.input(11)
        if (pin11state == GPIO.LOW and pin11prevst == GPIO.HIGH): # Falling edge happened
            # Measure runtime
            runtime_0 = runtime_1 # save previous runtime_1 for period calculation
            runtime_1 = time.time() # save start of shooting

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
                thread_create_num = thread_create_num + 1 # Increase thread number
                if (max_thread_num < (thread_create_num-thread_solved_num)): # Save max thread number
                    max_thread_num = (thread_create_num-thread_solved_num)
                thread.start_new_thread( save_image, (stream,filename) )
            except:
                print "Error: unable to start thread"

            # Measure image time and warn user if it was longer than 200ms
            captime = time.time() - captime
            if max_captime < captime:
                max_captime = captime
            captime_int = ((captime_int * 9)+captime)/10

            # Increase image number
            n = n + 1

            # Measure runtime
            runtime_2 = time.time()
            runtime_shoot = runtime_2 - runtime_1
            fps = int(1/(runtime_1 - runtime_0))
            load = ((load*9)+int(runtime_shoot*100/(runtime_1 - runtime_0)))/10

        # Save shoot pin state for edge detection
        pin11prevst = pin11state

        # Check watchdog input. It is pulse from source reel.
        # It always makes pulse when the reel is moving.
        # When we don't detect pulse for 10...15s, 
        # it is stopped, we can leave the loop by Loop = False.
        pin7state = GPIO.input(7) # Read actual pin state
        if ((pin7state == GPIO.HIGH) and (pin7prevst == GPIO.LOW)): # Rising edge happened, reel is turning
            last_wd_edge = time.time(); # Save the time of edge
            wd_edge_rising = time.time(); # Save the time of edge
        if ((pin7state == GPIO.LOW) and (pin7prevst == GPIO.HIGH)): # Falling edge happened, reel is turning
            last_wd_edge = time.time(); # Save the time of edge
            wd_period = time.time() - wd_edge_falling # This falling edge - prev falling edge
            wd_edge_falling = time.time(); # Save the time of edge
            wd_high = wd_edge_falling - wd_edge_rising # This falling edge - previous rising edge
            wd_duty = wd_high * 100 / wd_period

        # Save watchdog pin state for edge detection
        pin7prevst = pin7state

        # Check watchdog time
        elapsed_time = time.time() - last_wd_edge # Calculate elapsed time for last watchdog edge
        if max_elapsed_time < elapsed_time:
            max_elapsed_time = elapsed_time
        if (10 <= n and wd_timeout_in_s <= elapsed_time): # if 10 images were saved and elapsed time is more than wd_timeout_in_s
            break # Leave the loop, exit from script
        if (n < 10): # reinit wd timer in the begining of movie
           last_wd_edge = time.time()

        # Print info twice a sec
        if (infotime < time.time()):
            infotime = time.time() + 0.5

            str=filename
            str+=" tn=%2d" % (thread_create_num-thread_solved_num)
            str+=" mtn=%2d" % max_thread_num
            str+=" ct=%3dms" % (captime_int*1000)
            str+=" mct=%3dms" % (max_captime*1000)
            str+=" wd=%2ds" % int(wd_timeout_in_s-elapsed_time+1)
            str+=" mwd=%2ds" % int(wd_timeout_in_s-max_elapsed_time+1)
            str+=" wdd=%2d%%" % int(wd_duty)
            str+=" fps=%2d" % fps
            str+=" load=%2d%%" % load
            str+='            \r'
            sys.stdout.write(str)
            sys.stdout.flush()


    # Final actions before quit from scrip
    camera.stop_preview() # Switch off the camera
    camera.close()
    sys.stdout.write('\n')
    sys.stdout.flush()
    print "End of shooting" # Leave '\r' printing


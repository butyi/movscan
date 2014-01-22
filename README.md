MovScan
=======
8mm movie scanner/digitalizer with Raspberry Pi, RaspiCam, and an old Russian cine-projector.

Motivation
==========
I have a large suitcase of 8mm movies. To see one, I must prepare projector and environment which is too complicated.

Task
====
To prevent flashing of video, all slides must be shooted one by one, and join them to a video.

Flashing video example:
http://youtu.be/WmCGSHX4Mqk
This was created by a 30fps video camera.

Cine-projector
=============
I used the Russian projector what I have (Lomo Russ)

Camera
======
Target to have a camera which
- Has remote shoot possibility
- Has enough resolution
- Cheap
- Flexible

Best: Raspberry Pi with RaspiCam

Speed
=====
8mm movie is 12...15 fps.
Should be do as fast as possible
- raspistill needs 1s to make an image
- PiCamera python interface can make image every 650ms
- Calling capture with “use_video_port = True﻿” option, it can make image every 140ms

Shoot sensor
============
Opto gate was built in into the machine, which gives one pulse for every movie slide.

File save
============
To save a 150kB image to SD card is sometime 20ms, average is 150ms, but unfortunately sometime 2-3s. To not lose any slide, the script shoots the images into memory, and parallel task saves them to SD card. With this solution no images are lost.  
:-)

RaspiStill
==========
I have tried RaspiStill signal control. With -s option it waits  for SIGUSR1 to shoot.
I have written a C module to send SIGUSR1 signal when edge occurred on GPIO input.
Of course this was so slow (1fps)
(movscan.c)

PiCamera python
===============
Turned out, that in PiCamera, resolution change realises digital zoom (uses center part of CCD) → fast shot with high resolution → :-)
(movscan.py)

Create Video
============
Create 15fps video from images:
avconv -r 15 -f image2 -i image%05d.jpg -crf 15 -b 10M -preset slower ~/video.avi
Converting speed is ~60 fps on an 1.6GHz Ubuntu

Result
======
First test scanning result:
http://youtu.be/uJuZ71KQGfk

How to done it video:
http://youtu.be/PBL8H71WICk

Thank you for interesting!
=========================
V1.01
Butyi PlusPlus
2014.01.21.

www.butyi.hu
www.butyi.mooo.com
https://github.com/butyi


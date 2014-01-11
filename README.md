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
I used the Russian projector what I have

Camera
======
Target to have a camera which
- Has remote shoot possibility
- Has enough resolution
- Cheap

Best: Raspberry Pi with RaspiCam

Speed
=====
8mm movie is 12...15 fps.
Should be do as fast as possible
- raspistill needs 1s to make an image
- PiCamera python interface can make image every 650ms
- Calling capture_sequence with “use_video_port = True﻿” option, it can make image every 140ms

Shoot sensor
============
Opto gate was built in into the machine, which gives one pulse for every movie slide.

Difficulties
============
When PiCamera worked, I have written a python script to try GPIO also. Name io.py. After that PiCamera python stopped to work. “io.open - AttributeError: 'module' object has no attribute 'open' ”
Solution: my io.py in home folder overwrote the original python io module.
:-)

RaspiStill
==========
While python did not worked, I have tried RaspiStill signal control. With -s option it waits  for SIGUSR1 to shoot.
I have written a C module to send SIGUSR1 signal when edge occurred on GPIO input.
Of course this was slow (1fps)
(movscan.c)

PiCamera python again
=====================
With WEB help io.py was renamed, Python gets working again.
Turned out, that in PiCamera, resolution change realises digital zoom (uses center part of CCD) → fast shot with high resolution → :-)
(movscan.py)

Thousand of images 
==================
In case of B&W movies, images must be converted to B&W:
convert orig.jpg -type Grayscale ff.jpg
Auto white balance can be applied:
./autowhite.sh orig.jpg corr.jpg
central point mirroring due to optic:
convert orig.jpg -flip flipped.jpg
group commands above: find *.jpg -exec … \;

Create Video
============
Create 15fps video from images:
avconv -r 15 -f image2 -i image%05d.jpg -vcodec libx264 -crf 15 -preset slower ~/video.avi
It is so slow (1...2 fps)

Result
======
First test scanning result:
http://youtu.be/uJuZ71KQGfk

How to done it video:
http://youtu.be/zBhdDtUluQk

Thank you for interesting!
=========================
V1.00
Butyi PlusPlus
2014.01.11.

www.butyi.hu
www.butyi.mooo.com
https://github.com/butyi


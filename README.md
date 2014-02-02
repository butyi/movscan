MovScan
=======
8mm movie scanner/digitalizer with Raspberry Pi, RaspiCam, and an old Russian cine-projector.

Motivation
==========
I have a large suitcase of 8mm movies. To see one, I must prepare projector and environment which is too complicated. Would be good to digitalize them as automated way as possible.

ToDo
====
To prevent flashing of video, all slides must be shooted, and join them to a video.

Flashing video example:
http://youtu.be/WmCGSHX4Mqk
This was created by a 30fps video camera.

Cine-projector
==============
I used a Russian projector what I have: Lomo Russ

Camera
======
Target is to have a camera which
- Has remote shoot possibility
- Has enough resolution
- Cheap
- Fast
- Flexible 

Best: Raspberry Pi with RaspiCam

Speed
=====
8mm movie is usually 12...15 fps.
Scan should be as fast as possible
- raspistill needs 1s to make an image (1 fps)
- PiCamera python interface can take image every 650ms (1.5 fts)
- With “use_video_port = True﻿” option, it can take image to file every 140ms (7 fps)
- Take image to RAM just 60ms (16 fps) but save to file in parallel threads also needs runtime

Finally safe speed is 8 fps -> half speed

CCD, optic and LED
==================
I have created a paper console for CCD. The optic is the original one. 10W power LED is used instead of light bulb. 

Shoot sensor
============
Opto gate was built in into the machine, which gives one pulse for every movie slide. Originally there were three shadow plates. One hides the slide change. The other two just multiplies the shadow frequency. Now one plate is used to give shot pulse, but all three plates were removed to not make any shadow. This because any shadow disturbed the camera automatic light control algorithm. 

Watchdog sensor
===============
It gives pulse from source reel. It always makes pulse when the reel is moving. When we don't detect pulse for 10...15s, most likely it is stopped due to end of the film, we can exit from shoot-loop. 

RaspiStill
==========
I have tried RaspiStill signal control first. With -s option it waits for SIGUSR1 to shoot. I have written a C module to send SIGUSR1 signal when edge occurred on GPIO input. Of course this was so slow (1fps), but worked.

(movscan.c)

White balance
=============
In all white balance options the automated trim algorithm remains active, which results unstable flying colours also in case of black and white films.
To prevent this negative effect, white balance must be switched off in RaspiCam.
But this results yellow images with original light bulb.
Using cold white LED solved the white balance issues. 

Main bash script
================
The procedure is managed by a bash script
- Prepare folder
- Take images
- Create video
- Save video to NAS
- Upload video to Youtube
- Delete video and images

Capture images
==============
PiCamera python lib is used:
http://picamera.readthedocs.org/en/release-0.8/index.html

While I use the original optic, the real picture in only a small central part of CCD. To not lose resolution, full resolution picture should be saved, which results slow save. Faster save would need small resolution picture. Crop function realizes digital zoom, which is exactly the best: fast save with high resolution.

File save
=========
To save a 150kB image to SD card is sometime 20ms, average is 150ms, but unfortunately sometime 2-3s. 
To not lose any slide, the script shoots the images into memory, and parallel tasks save them to SD card. 
With this solution no images are lost. 

Create Video
============
Create 15fps video from images:
avconv -g 0 -r 15 -f image2 -i image%05d.jpg -qscale 1 -b 10M -preset slower ~/video.avi
It is not too fast on RPI (2...3 fps)

Copy video file to NAS
======================
The NAS is mounted by main bash scripts.
sudo mount -t cifs //192.168.0.134/volume_1 /home/pi/nas -o username=$NAS_USER,password=$NAS_PASS
If the mount and the copy to NAS was not successful, the video file is not deleted from SD card
Folder and file check on NAS is also done by main bash script

Upload to YouTube
=================
The youtube-upload bash script uploads the video to Youtube from my main bash script.
http://code.google.com/p/youtube-upload/
It supports all settings of Youtube, including --notlisted

E-mail notify
=============
Finally a python script sends an Email report with Youtube link to video.

"Hello,
The MovScan has digitalized a new cine film: mozgofilm-06
The film has been uploaded to YouTube, but it is most probable still in processing by YouTube.
Link to the film: http://www.youtube.com/watch?v=uJuZ71KQGfk
Enjoy! :-)
Butyi"

Result
======
First test scanning result:
http://youtu.be/uJuZ71KQGfk

How to done it video:
http://youtu.be/PBL8H71WICk

Thank you for attention!
========================
Butyi
2014.01.26.

www.butyi.hu
www.butyi.mooo.com
https://github.com/butyi



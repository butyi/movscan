#!/bin/bash
# Movie digitalizer scipt. ms => Movie Scan

#Script configuration
set -e # the script terminates as soon as any command fails

#Functions
display_usage() {
	echo -e "Movie digitalizer scipt\n"
	echo -e "Usage:\n$0 n [-m]\n"
        echo -e "   n : number of film in format %02d\n"
        echo -e "  -m : Monochrome images\n"
}

line() {
        echo -e "------------------------------------\n"
}


# Read my NAS account data (NAS_USER, NAS_PASS)
. ~/.my-nas-account

# Variables
FOLDERNAME=mozgofilm-$1
FILENAME=$FOLDERNAME.avi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
	display_usage
	exit 0
fi

# jump to temp folder where images will be stored
line
echo -e "Step 1: Jump to ~/temp folder\n"
cd ~/temp

# Shoot slides of movie. The sript exits at the end of movie automaticly
line
if [[ $2 == "-m" ]]
then
        echo -e "Step 2: Shooting monocrome slides\n"
        sudo python ~/movscan/sources/py/movscan.py -m -p
else
        echo -e "Step 2: Shooting color slides\n"
        sudo python ~/movscan/sources/py/movscan.py -p
fi

# Create video from images
line
echo -e "Step 3: Creating 15fps video by concatenating images\n"
avconv -r 15 -f image2 -i image%05d.jpg -crf 15 -b 10M -preset slower ~/$FILENAME

# delete images
line
echo -e "Step 4: Delete images\n"
sudo rm *

# mount NAS if it is not yet mounted
if ! mountpoint -q /home/pi/nas
then
  line
  echo -e "Step 5: Mount NAS\n"
  sudo mount -t cifs //192.168.0.134/volume_1 /home/pi/nas -o username=$NAS_USER,password=$NAS_PASS
fi

# copy video to NAS
line
echo -e "Step 6: Copy video file to NAS\n"
mkdir ~/nas/SAJAT/HOME_VIDEO/8mm/$FOLDERNAME
cp  ~/$FILENAME ~/nas/SAJAT/HOME_VIDEO/8mm/$FOLDERNAME

# upload video to YouTube
line
echo -e "Step 7: Upload video to YouTube\n"
youtube-upload --email=$GMAIL --password=$GPASS --unlisted --title="$FOLDERNAME" --description="$FOLDERNAME" --category=People --keywords="8mm, film, movie, cine-projector, raspberry pi, raspicam, scan, digitalize" ~/$FILENAME

# delete video
line
echo -e "Step 8: Delete video\n"
sudo rm ~/$FILENAME


echo -e "Hurray, Finished!\n"


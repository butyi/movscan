#!/bin/bash
# Movie digitalizer scipt. ms => Movie Scan

#Script configuration
set -e # the script terminates as soon as any command fails

#Functions
display_usage() {
	echo -e "Movie digitalizer scipt\n"
	echo -e "Usage:\n$0 [bw|color]\n"
}

line() {
        echo -e "------------------------------------\n"
}

# Variables
DATE=`date +%F-%k-%M-%S`

# if less than two arguments supplied, display usage
if [  $# -le 1 ]
then
        echo -e "Missing parameter!\n"
 	display_usage
fi

# if less than two arguments supplied, display usage
if [  $# -lt 1 ]
then
	display_usage
	exit 1
fi

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
	display_usage
	exit 0
fi

# create folder for images
line
echo -e "Step 1: Creating folder $DATE\n"
mkdir ~/$DATE # Create the folder
cd ~/$DATE # Jump to folder

# Shoot slides of movie. The sript exits at the end of movie automaticly
line
echo -e "Step 2: Shooting slides\n"
sudo python ~/movscan/sources/py/movscan.py

# If the movie is Black & White (bw), than convering images to grayscale
line
if [  $1 == "bw" ]
then
        echo -e "Step 3: Converting images to grayscale\n"
	find *.jpg -print -exec sudo convert '{}' -type Grayscale '{}' \;
fi
if [  $1 == "color" ]
then
        echo -e "Step 3: Applying auto-white-balance on images\n"
        find *.jpg -print -exec sudo bash ~/mytools/bash/autowhite.sh '{}' '{}' \;
fi

# Create video from images
line
echo -e "Step 4: Merging images to video\n"
avconv -r 15 -f image2 -i image%05d.jpg -crf 15 -b 10M -preset slower ~/$DATE/video-$DATE.avi

echo -e "Hurray! Video is now available: ~/$DATE/video-$DATE.avi\n"


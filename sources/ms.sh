#!/bin/bash
# Movie digitalizer scipt. ms => Movie Scan

#Script configuration
set -e # the script terminates as soon as any command fails

#Functions
display_usage() {
	echo -e "Movie digitalizer scipt\n"
	echo -e "Usage:\n$0 [-m]\n"
        echo -e "  -m : Monochrome images\n"
}

line() {
        echo -e "------------------------------------\n"
}

# Variables
DATE=`date +%F`

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
if [[ $# == "-m" ]]
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
avconv -r 15 -f image2 -i image%05d.jpg -crf 15 -b 10M -preset slower ~/$DATE/video-$DATE.avi

echo -e "Hurray! Video is now available: ~/$DATE/video-$DATE.avi\n"


#!/bin/bash
# Movie digitalizer scipt. ms => Movie Scan
display_usage() { 
	echo "Movie digitalizer scipt" 
	echo -e "\nUsage:\n$0 [bw|color] \n" 
}
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

# create folder for images if does not yet exist
if [ ! -d ~/pics ]
then
	mkdir ~/pics
fi

# Jump to images folder
cd ~/pics

# clear content of folder
sudo rm ~/pics/*

# Shoot slides of movie. The sript exits at the end of movie automaticly
sudo python ~/movscan/sources/py/movscan.py

# If the movie is Black & White (bw), than convering images to grayscale
if [  $1 == "bw" ] 
then 
	find *.jpg -print -exec sudo convert '{}' -type Grayscale '{}' \;
fi 

# Create video from images -b 10M
avconv -r 15 -f image2 -i image%05d.jpg -crf 15 -preset slower ~/video.avi



#!/bin/bash
# Movie digitalizer scipt. ms => Movie Scan

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
. ~/.my-accounts

# Variables
FOLDERNAME=mozgofilm-$1
FILENAME=$FOLDERNAME.avi
NASPATH=~/nas/SAJAT/HOME_VIDEO/8mm
NASSAVE=0
YOUTUBE=0

# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
	display_usage
	exit 0
fi

# jump to temp folder where images will be stored
line
echo -e "----- Jump to ~/temp folder\n"
cd ~/temp
if [ $? -ne 0 ]; then
  echo -e "ERROR! Cannot jump to ~/temp folder."
  exit
fi

# Shoot slides of movie. The sript exits at the end of movie automaticly
line
if [[ $2 == "-m" ]]
then
        echo -e "----- Shooting monocrome slides\n"
        sudo python ~/movscan/sources/py/movscan.py -m -p
else
        echo -e "----- Shooting color slides\n"
        sudo python ~/movscan/sources/py/movscan.py -p
fi
if [ $? -ne 0 ]; then
  echo -e "ERROR! Cannot take images."
  exit
fi

# Create video from images
line
echo -e "Step 3: Creating 15fps video by concatenating images\n"
avconv -r 15 -f image2 -i image%05d.jpg -crf 15 -b 10M -preset slower ~/$FILENAME
if [ $? -ne 0 ]; then
  echo -e "ERROR! Cannot make video."
  exit
fi

# delete images
line
echo -e "----- Delete images\n"
sudo rm *
if [ $? -ne 0 ]; then
  echo -e "  WARNING! Cannot delete images."
fi

# copy video to NAS if possible
line
echo -e "----- Copy video to NAS\n"
if ! mountpoint -q /home/pi/nas
then
  echo -e "  - Mount NAS\n"
  sudo mount -t cifs //192.168.0.134/volume_1 /home/pi/nas -o username=$NAS_USER,password=$NAS_PASS
  # return value must not be tested here, because must continue even if mount has failed
fi

if mountpoint -q /home/pi/nas # If mount is now visible
then
  # copy video to NAS
  echo -e "  - Copy video\n"
  if [ ! -d $NASPATH/$FOLDERNAME ] #if folder does not exist on NAS
  then
    mkdir $NASPATH/$FOLDERNAME # Create it
  fi
  if [ -d $NASPATH/$FOLDERNAME ] #if folder exists on NAS
    if [ -f $NASPATH/$FOLDERNAME/$FILENAME ] # if same name is already in the folder
    then
      rm $NASPATH/$FOLDERNAME/$FILENAME # Delete it
    fi
    if [ ! -f $NASPATH/$FOLDERNAME/$FILENAME ] # if same file is not in the folder
      cp ~/$FILENAME $NASPATH/$FOLDERNAME # Copy the new file to NAS
      if [ $? -eq 0 ]; then
        NASSAVE=1 # NAS save was successfull
        exit
      fi
    fi
  fi
fi

# upload video to YouTube
line
echo -e "----- Upload video to YouTube\n"

# Check internet connection (Thanks to Jesse: http://stackoverflow.com/users/2083761/jesse)
for interface in $(ls /sys/class/net/ | grep -v lo);
do
  if [[ $(cat /sys/class/net/$interface/carrier) = 1 ]]; then OnLine=1; fi
done
if ! [ $OnLine ]; then echo "  There is not Internet connection. YouTube upload is skipped."; fi
if [ $OnLine ]; then
  if [ -f ~/youtube-link ] # if previous link still exists
  then
    rm ~/youtube-link # Delete it
    if [ $? -ne 0 ]; then
      echo -e "  WARNING! Cannot delete link."
    fi
  fi
  if [ ! -f ~/youtube-link ] # if there is no link
  then
    youtube-upload --email=$GMAIL --password=$GPASS --unlisted --title="$FOLDERNAME" --description="$FOLDERNAME" --category=People --keywords="8mm, film, movie, cine-projector, raspberry pi, raspicam, scan, digitalize" ~/$FILENAME >~/youtube-link
    if [ $? -eq 0 ]; then
      YOUTUBE=1 # upload was successfull
    fi
  fi
fi

# delete video if it is stored on NAS
if [ $NASSAVE ]; then
  line
  echo -e "----- Delete video\n"
  sudo rm ~/$FILENAME
fi

# Send report mail if it was succesfully uploaded to YouTube
if [ $YOUTUBE ]; then
  line
  echo -e "----- Send report e-mail\n"
  python sendmail.py $GAMIL $GPASS $FOLDERNAME `cat ~/youtube-link`
fi


echo -e "Hurray, Finished!\n"


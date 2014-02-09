#!/bin/bash
# Movie digitalizer scipt. ms => Movie Scan
# Copyright: BENCSIK Janos <copyright@butyi.hu>
# License : WTFPL v2 <http://www.wtfpl.net/txt/copying/>

#Functions
display_usage() {
	echo "Movie film digitalizer scipt"
	echo "Usage:\n$0 x [-s|n]"
        echo "   x : number of film in format %02d"
        echo "  -s : Super film"
        echo "  -n : Normal film"
}

line() {
        echo "------------------------------------"
}
# Read my NAS account data (NAS_USER, NAS_PASS)
. ~/.my-accounts

# Variables
FOLDERNAME=mozgofilm-$1
FILENAME=$FOLDERNAME.avi
TXTFILENAME=$FOLDERNAME.txt
NASPATH=~/nas/SAJAT/HOME_VIDEO/8mm
YELLOW_TEXT='\e[1;33m'
RED_TEXT='\e[1;31m'
GREEN_TEXT='\e[1;32m'
BLUE_TEXT='\e[1;34m'
ENDCOLOR='\e[0m'


# check whether user had supplied -h or --help . If yes display usage
if [[ ( $# == "--help") ||  $# == "-h" ]]
then
	display_usage
	exit 0
fi

# Check internet connection (Thanks to Jesse: http://stackoverflow.com/users/2083761/jesse)
line
echo "Check internet connection."
for interface in $(ls /sys/class/net/ | grep -v lo);
do
  if [[ $(cat /sys/class/net/$interface/carrier) = 1 ]]; then OnLine=1; fi
done

# Try to create target folder on NAS and an empty text file for description
line
echo "----- Prepare target folder on NAS"
if ! [ $OnLine ]; then echo "There is not LAN connection. NAS task is skipped."; fi
if [ $OnLine ]; then
  if ! mountpoint -q /home/pi/nas
  then
    echo "Mount NAS"
    echo "sudo mount -t cifs $NASDRIVE /home/pi/nas -o username=NAS_USER,password=NAS_PASS"
    sudo mount -t cifs $NASDRIVE /home/pi/nas -o username=$NAS_USER,password=$NAS_PASS
    # return value must not be tested here, because must continue even if mount has failed
  else
    echo "NAS is already mounted."
  fi

  if mountpoint -q /home/pi/nas # If mount is now visible
  then
    # prepare NAS
    if [ ! -d $NASPATH/$FOLDERNAME ] #if folder does not exist on NAS
    then
      echo "Make dir $FOLDERNAME"
      mkdir $NASPATH/$FOLDERNAME # Create it
    else
      echo "Folder $FOLDERNAME already exists."
    fi
    if [ -d $NASPATH/$FOLDERNAME ] #if folder exists on NAS
    then
      if [ ! -f $NASPATH/$FOLDERNAME/$TXTFILENAME ] # if txt file is not yet in the folder
      then
        echo "Create text file $NASPATH/$FOLDERNAME/$TXTFILENAME"
        touch $NASPATH/$FOLDERNAME/$TXTFILENAME
      else
        echo "File $NASPATH/$FOLDERNAME/$TXTFILENAME already exists."
      fi
      if [ ! -s $NASPATH/$FOLDERNAME/$TXTFILENAME ] # if txt file is empty
      then
        echo -e "${YELLOW_TEXT}WARNING! File $NASPATH/$FOLDERNAME/$TXTFILENAME is empty. Please fill it up during processing!${ENDCOLOR}"
      fi
    fi
  fi
fi


# jump to temp folder where images will be stored
line
echo "----- Jump to ~/temp folder"
cd ~/temp
if [ $? -ne 0 ] # cd command faults
then
  echo -e "${RED_TEXT}ERROR! Cannot jump to ~/temp folder.${ENDCOLOR}"
  exit
fi
if [ "$(ls -A ~/temp)" ] # If temp folder is not empty
then
  echo -e "${BLUE_TEXT}There are already images available in temp folder. Do you want to overwrite them? (y/n)?${ENDCOLOR}"
  read choice
  case "$choice" in
    y|Y ) NEW_IMAGES=1;;
    n|N ) ;;
    * ) echo -e "${RED_TEXT}Invalid answer!${ENDCOLOR}"; exit;;
  esac
  if [ $NEW_IMAGES ]; then
    cd ~/
    sudo rm -r temp # Delete all images in folder
    mkdir temp
    cd ~/temp
  fi
else # If temp folder is empty
  echo "The temp folder is empty."
  NEW_IMAGES=1
fi

# Shoot slides of movie. The sript exits at the end of movie automaticly
if [ $NEW_IMAGES ]; then
  line
  echo "----- Shooting slides"
  echo "sudo python ~/movscan/sources/py/movscan.py $2"
  sudo python ~/movscan/sources/py/movscan.py $2
  if [ $? -ne 0 ]; then
    echo -e "${RED_TEXT}ERROR! Cannot take images.${ENDCOLOR}"
    exit
  fi
fi

# Ask user whether the film was color or grayscale
echo -e "${BLUE_TEXT}Was the film color or grayscale? (c/g)?${ENDCOLOR}"
read choice
case "$choice" in
  c|C ) echo "color"; FILM_COLOR=1;;
  g|G ) echo "grayscale"; FILM_GRAYSCALE=1;;
  * ) echo -e "${RED_TEXT}Invalid answer!${ENDCOLOR}"; exit;;
esac


# Create video from images
line
echo "----- Creating 15fps video by concatenating images"
if [ -f ~/$FILENAME ] # if there is video file with same name
then
  rm ~/$FILENAME # delete it
fi

if [ $FILM_COLOR ];
then
  echo "avconv -g 0 -r 15 -f image2 -i image%05d.jpg -qscale 1 -b 15M -preset slower ~/$FILENAME"
  avconv -g 0 -r 15 -f image2 -i image%05d.jpg -qscale 1 -b 15M -preset slower ~/$FILENAME
fi

if [ $FILM_GRAYSCALE ];
then
  echo "avconv -g 0 -r 15 -f image2 -i image%05d.jpg -flags gray -qscale 1 -b 15M -preset slower ~/$FILENAME"
  avconv -g 0 -r 15 -f image2 -i image%05d.jpg -flags gray -qscale 1 -b 15M -preset slower ~/$FILENAME
fi

if [ $? -ne 0 ]; then
  echo -e "${RED_TEXT}ERROR! Cannot make video.${ENDCOLOR}"
  exit
fi

# delete images
line
echo "----- Delete images"
cd ~/
sudo rm -r temp # Delete all images in folder
mkdir temp
cd ~/temp
if [ $? -ne 0 ]; then
  echo -e "${YELLOW_TEXT}WARNING! Cannot delete images.${ENDCOLOR}"
else
  echo "OK. Images are deleted."
fi

# copy video to NAS if possible
line
echo "----- Copy video to NAS"
if ! [ $OnLine ]; then echo "There is not LAN connection. NAS save is skipped."; fi
if [ $OnLine ]; then
  if ! mountpoint -q /home/pi/nas
  then
    echo "Mount NAS"
    echo "sudo mount -t cifs $NASDRIVE /home/pi/nas -o username=NAS_USER,password=NAS_PASS"
    sudo mount -t cifs $NASDRIVE /home/pi/nas -o username=$NAS_USER,password=$NAS_PASS
    # return value must not be tested here, because must continue even if mount has failed
  fi

  if mountpoint -q /home/pi/nas # If mount is now visible
  then
    # copy video to NAS
    if [ ! -d $NASPATH/$FOLDERNAME ] #if folder does not exist on NAS
    then
      echo "Make dir $FOLDERNAME"
      mkdir $NASPATH/$FOLDERNAME # Create it
    fi
    if [ -d $NASPATH/$FOLDERNAME ] #if folder exists on NAS
    then
      if [ -f $NASPATH/$FOLDERNAME/$FILENAME ] # if same name is already in the folder
      then
        echo "Delete video $NASPATH/$FOLDERNAME/$FILENAME"
        rm $NASPATH/$FOLDERNAME/$FILENAME # Delete it
      fi
      if [ ! -f $NASPATH/$FOLDERNAME/$FILENAME ] # if same file is not in the folder
      then
        echo "Copy video to $NASPATH/$FOLDERNAME/$FILENAME"
        cpb ~/$FILENAME $NASPATH/$FOLDERNAME/$FILENAME # Copy the new file to NAS with progress bar
        if [ $? -eq 0 ]; then
          NASSAVE=1 # NAS save was successfull
        fi
      fi
    fi
  fi
fi

# upload video to YouTube
line
echo "----- Upload video to YouTube"

if ! [ $OnLine ]; then echo "There is not Internet connection. YouTube upload is skipped."; fi
if [ $OnLine ]; then
  if [ -f ~/youtube-link ] # if previous link still exists
  then
    echo "Delete Youtube link"
    rm ~/youtube-link # Delete it
    if [ $? -ne 0 ]; then
      echo -e "${YELLOW_TEXT}WARNING! Cannot delete link.${ENDCOLOR}"
    fi
  fi
  if [ ! -f ~/youtube-link ] # if there is no link
  then
    # Find description
    if [ -s $NASPATH/$FOLDERNAME/$FOLDERNAME.txt ] # if description is not empty
    then
      DESCRIPTION=$(< $NASPATH/$FOLDERNAME/$FOLDERNAME.txt)
      echo "Description available."
    else
      DESCRIPTION=$FOLDERNAME
      echo -e "${YELLOW_TEXT}Description missing.${ENDCOLOR}"
    fi
    youtube-upload --email=$GMAIL --password=$GPASS --unlisted --title="$FOLDERNAME" --description="$DESCRIPTION" --category=People --keywords="8mm, film, movie, cine-projector, raspberry pi, raspicam, scan, digitalize" ~/$FILENAME >~/youtube-link
    if [ $? -eq 0 ]; then
      echo "Add video to playlist 'Mozgofilmek'"
      youtube-upload --email=$GMAIL --password=$GPASS --add-to-playlist=$PL_MOZGOFILMEK $(<~/youtube-link)
      if [ $? -eq 0 ]; then
        YOUTUBE=1 # upload was successfull
      fi
    fi
  fi
fi

line
echo "----- Delete video"
# delete video if it is stored on NAS
if [ $NASSAVE ]; then
  sudo rm ~/$FILENAME
fi
if ! [ $NASSAVE ]; then
  echo "~/$FILENAME is not deleted, because NAS save was not successfull."
fi

# Send report mail if it was succesfully uploaded to YouTube
line
echo "----- Send report e-mail ($GTO)"
if [ $YOUTUBE ]; then
  python /home/pi/movscan/sources/py/sendmail.py $GPASS "$GTO" $FOLDERNAME $(<~/youtube-link) "$DESCRIPTION"
  if [ $? -eq 0 ]; then
    echo "Email has sent."
  else
    echo -e "${RED_TEXT}ERROR! Email has not sent.${ENDCOLOR}"
  fi
else
  echo "Email has not sent, because YouTube upload was not successfull."
fi

echo -e "${GREEN_TEXT}Hurray, Finished!${ENDCOLOR}"

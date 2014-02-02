#!/bin/bash
# Movie digitalizer scipt. ms => Movie Scan

#Functions
display_usage() {
	echo -e "Movie digitalizer scipt\n"
	echo -e "Usage:\n$0 x [-s|n] [-m|c] [-p]\n"
        echo -e "   x : number of film in format %02d\n"
        echo -e "  -m : Monochrome images\n"
        echo -e "  -c : Color images\n"
        echo -e "  -s : Super film\n"
        echo -e "  -n : Normal film\n"
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
if [ $? -ne 0 ] # cd command faults
then
  echo -e "ERROR! Cannot jump to ~/temp folder."
  exit
fi
if [ "$(ls -A ~/temp)" ] # If temp folder is not empty
then
  cd ~/
  sudo rm -r temp # Delete all images in folder
  mkdir temp
  cd ~/temp
fi

# Shoot slides of movie. The sript exits at the end of movie automaticly
line
echo -e "----- Shooting slides ($2 $3)\n"
sudo python ~/movscan/sources/py/movscan.py -p $2 $3
if [ $? -ne 0 ]; then
  echo -e "ERROR! Cannot take images."
  exit
fi

# Create video from images
line
echo -e "----- Creating 15fps video by concatenating images\n"
if [ -f ~/$FILENAME ] # if there is video file with same name
then
  rm ~/$FILENAME # delete it
fi
avconv -g 0 -r 15 -f image2 -i image%05d.jpg -qscale 1 -b 10M -preset slower ~/$FILENAME
if [ $? -ne 0 ]; then
  echo -e "ERROR! Cannot make video."
  exit
fi

# delete images
line
echo -e "----- Delete images\n"
cd ~/
sudo rm -r temp # Delete all images in folder
mkdir temp
cd ~/temp
if [ $? -ne 0 ]; then
  echo -e "  WARNING! Cannot delete images."
fi

# Check internet connection (Thanks to Jesse: http://stackoverflow.com/users/2083761/jesse)
for interface in $(ls /sys/class/net/ | grep -v lo);
do
  if [[ $(cat /sys/class/net/$interface/carrier) = 1 ]]; then OnLine=1; fi
done

# copy video to NAS if possible
line
echo -e "----- Copy video to NAS\n"
if ! [ $OnLine ]; then echo "  There is not LAN connection. NAS save is skipped."; fi
if [ $OnLine ]; then
  if ! mountpoint -q /home/pi/nas
  then
    echo -e "  - Mount NAS\n"
    sudo mount -t cifs $NASDRIVE /home/pi/nas -o username=$NAS_USER,password=$NAS_PASS
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
    then
      if [ -f $NASPATH/$FOLDERNAME/$FILENAME ] # if same name is already in the folder
      then
        rm $NASPATH/$FOLDERNAME/$FILENAME # Delete it
      fi
      if [ ! -f $NASPATH/$FOLDERNAME/$FILENAME ] # if same file is not in the folder
      then
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
echo -e "----- Upload video to YouTube\n"

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
    # Find description
    if [ -f $NASPATH/$FOLDERNAME/$FOLDERNAME.txt ] # if description is alredy available
    then
      DESCRIPTION=$(< $NASPATH/$FOLDERNAME/$FOLDERNAME.txt)
      echo -e "  Description available."
    else
      DESCRIPTION=$FOLDERNAME
      echo -e "  Description missing."
    fi
    youtube-upload --email=$GMAIL --password=$GPASS --unlisted --title="$FOLDERNAME" --description="$DESCRIPTION" --category=People --keywords="8mm, film, movie, cine-projector, raspberry pi, raspicam, scan, digitalize" ~/$FILENAME >~/youtube-link
    if [ $? -eq 0 ]; then
      YOUTUBE=1 # upload was successfull
    fi
  fi
fi

line
echo -e "----- Delete video\n"
# delete video if it is stored on NAS
if [ $NASSAVE ]; then
  sudo rm ~/$FILENAME
fi
if ! [ $NASSAVE ]; then
  echo -e "  ~/$FILENAME is not deleted, because NAS save was not successfull.\n"
fi

# Send report mail if it was succesfully uploaded to YouTube
line
echo -e "----- Send report e-mail ($GTO)\n"
if [ $YOUTUBE ]; then
  python /home/pi/movscan/sources/py/sendmail.py $GPASS "$GTO" $FOLDERNAME $(<~/youtube-link) "$DESCRIPTION"
fi
if ! [ $YOUTUBE ]; then
  echo -e "  Email has not sent, because YouTube upload was not successfull.\n"
fi

if [ $? -eq 0 ]; then
  echo -e "Hurray, Finished!\n"
fi


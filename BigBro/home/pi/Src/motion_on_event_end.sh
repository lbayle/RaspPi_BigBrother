#!/bin/bash
# LoB 2017-08-05
# Command to be executed when an event ends after a period of no motion
# (default: none). The period of no motion is defined by option event_gap.

# action:
# check all the photos from the most recent event,
# find best picture and send it per email.

# this is similar to option "output_pictures best" as it picks the same picture,
# but with the benefit that all the pictures of the period are saved on the server
# for later analisis.

# motion options to be set:
# picture_filename %v_%D_%q_%Y%m%d_%H%M%S
# output_pictures on


MY_PID=$$
MY_FILENAME=$(basename "$0")
MY_FILENAME_NO_EXT=$(basename "$0" .sh)  # filename without extension

LOG_FILE="/data/log/bigbro_global_activity.log"
DIR_PICTURES="/var/www/html/images/camera/captures"
DIR_SENT_PICTURES="/var/www/html/images/camera/selected"

LOCK_FILE=/tmp/${MY_FILENAME_NO_EXT}.lock

PHONE_ADMIN1="+33xxxxxxxxx" # Louis
PHONE_ADMIN2="+33xxxxxxxxx" # Francoise

# specify multiple recipients by joining them with a comma
destEmail=louis.bayle@gmail.com
#destEmail=louis.bayle@gmail.com,lbayle.trash@gmail.com

##################################################################
## TOOLS
##################################################################

function f_exit {
  rm -f $LOCK_FILE
  f_trace "end (exitCode=$1)"
  exit $1
}

# --------------------------------------------------------
# usage : f_trace [NO_DATE] "<message>"
function f_trace {

  if [ "xNO_DATE"  = "x$1" ] ; then
    local trace="[${USER}::${MY_FILENAME}] $2"
  else
    local trace="$(date '+%Y-%m-%d %T') [${USER}::${MY_FILENAME}] $1"
  fi
  echo $trace
  echo $trace >> $LOG_FILE
}

# --------------------------------------------------------
# find the picture of latest event with most changed pixels
# => FAST, rely on motion detections only
function f_findMaxPixFile {
  local maxChangedPixels=0
  local changedPixels=0
  for fname in $(ls ${latestEvent}_*.jpg) ; do
    changedPixels=$(echo ${fname} | cut -d'_' -f2)
    [ $maxChangedPixels -lt $changedPixels ] && maxChangedPixels=$changedPixels
  done
  imageFilename=$(ls ${latestEvent}_${maxChangedPixels}_*.jpg  | head -1)
}

# --------------------------------------------------------
# Compare the pictures of the latest event to the reference image.
# the reference image is the pre-capture picture (before motion is detected by the camera).
# A filter is previously applied, to avoid alerts on brightness changes (clouds)
# => SLOW, but avoids some fake alerts (clouds)
# set motion.conf :
#    pre_capture 3
#    picture_filename %v_%D_%q_%Y%m%d_%H%M%S
function f_findBestComparedFile {

  local EMBOSS_ARGS="-m 2 -d 5" # see http://www.fmwconcepts.com/imagemagick/emboss/index.php

  # get refFile, and apply highpass filter
  local refFile=$(ls ${latestEvent}_0_*.jpg | head -1) # there should be only one with changedPix=0
  local refFileEmboss=${DIR_PICTURES}/${latestEvent}_0_emboss_ref.jpg
  /home/pi/Src/emboss.sh ${EMBOSS_ARGS} $refFile $refFileEmboss

  # now compare event picture to refFile
  local maxCompareRatio=0
  local compareRatio=0
  for fname in $(ls ${latestEvent}_*.jpg) ; do
    /home/pi/Src/emboss.sh ${EMBOSS_ARGS} ${fname} /tmp/emboss_${fname}
    # find the change-ratio + make it string-comparable
    compareRatio=$(compare -metric PSNR $refFileEmboss /tmp/emboss_${fname} /tmp/diff_${fname} 2>&1)
    compareRatio=$( echo "$compareRatio" | sed -r 's/\./0/g' | cut -c 1-6) # 25.2345 => 250234
    if [[ $maxCompareRatio -lt $compareRatio ]] ; then
      maxCompareRatio=$compareRatio
      imageFilename=${fname}
    fi
  done

  # cleanup
  rm /tmp/emboss_${latestEvent}_*.jpg
  rm /tmp/diff_${latestEvent}_*.jpg

  # Note: images are identical if compareRatio is high.
  # if ratio > 28% then it is considered as fake alert (clouds, birds, ...)
  f_trace " maxCompareRatio=$maxCompareRatio --- ${fname}"
  if [[ $maxCompareRatio -gt 280000 ]] ; then
    f_trace "Fake ALERT: maxCompareRatio=$maxCompareRatio > 280000 (28%), exit 0"
    f_exit 0
  fi

}

# --------------------------------------------------------
# find the picture of latest event with most changed pixels, and compare it to
# the reference image (pre-captured picture, before motion is detected by the camera).
# => quite FAST & reliable
function f_findMaxPixFileAndCompare {

  # get refFile, and apply highpass filter
  local refFile=$(ls ${latestEvent}_0_*.jpg | head -1) # changedPix=0

  # get picture with most changed pixels, based on filename
  local maxChangedPixels=0
  local changedPixels=0
  for fname in $(ls ${latestEvent}_*.jpg) ; do
    changedPixels=$(echo ${fname} | cut -d'_' -f2)
    [ $maxChangedPixels -lt $changedPixels ] && maxChangedPixels=$changedPixels
  done

  # set global variables
  imageFilename=$(ls ${latestEvent}_${maxChangedPixels}_*.jpg  | head -1)
  diffFile=${latestEvent}_0_diff.jpg

  # apply brightness filter
  # https://stackoverflow.com/questions/39678335/ignoring-differences-in-brightness-with-imagemagick-compare-tool
  # but -normalize not recognized ?!?
  # local refFileNorm=/tmp/norm_${refFile}.ppm
  # local imageFileNorm=/tmp/norm_${imageFilename}.ppm
  # convert ${refFile} -normalize ${refFileNorm}
  # convert ${imageFilename} -normalize ${imageFileNorm}

  # compare with reference image
  compareRatio=$(compare -fuzz 15% -metric PSNR ${refFile} ${imageFilename} ${DIR_PICTURES}/${diffFile} 2>&1)
  f_trace "compareRatio=$compareRatio %"

  # Note: images are identical if compareRatio is high.
  # if ratio > 28% then it is considered as fake alert (clouds, birds, ...)
  compareRatio=$( echo "$compareRatio" | sed -r 's/\./0/g' | cut -c 1-6) # 25.2345 => 250234
  if [[ $compareRatio -gt 280000 ]] ; then
    f_trace "Fake ALERT: compareRatio=$compareRatio > 280000 (28%), exit 0"
    f_exit 0
  fi

}

##################################################################
## MAIN
##################################################################

f_trace "event_stop !"

# --------------------------------------------
# wait for previous event to be processed
while [ -f $LOCK_FILE ] ; do
  pid=$(head -n 1 $LOCK_FILE)
  ps -p $pid > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    f_trace "wait for previous event to be processed (PID=${pid}) ..."
    sleep 5;
  else
    f_trace "process ${pid} is not alive, let's go !"
    break # it's my turn !
  fi
done

# write lock file
echo "$MY_PID" > $LOCK_FILE


cd ${DIR_PICTURES}

# --- find latest event
latestFilename=$(ls -t | head -1)
latestEvent=$(echo ${latestFilename} | cut -d'_' -f1)

#echo "latestFilename = $latestFilename"
#echo "event          = $latestEvent"
echo "event = $latestEvent" >> $LOCK_FILE


# --- find the best picture of latest event
#f_findBestComparedFile
#f_findMaxPixFile
f_findMaxPixFileAndCompare

if [ ! -f ${DIR_PICTURES}/${imageFilename} ] ; then
   f_trace "ERROR File not found: ${DIR_PICTURES}/${imageFilename}"
else
   f_trace "Selected image: ${imageFilename}"
fi

# --- send SMS alert
f_trace "send SMS alert"
# Note: service must be activated: sudo update-rc.d gammu-smsd enable
sudo gammu-smsd-inject TEXT ${PHONE_ADMIN1} -text "WARNING Barcelo BigBro motion detection ${latestEvent}"

# --- resize image to reduce mobile-phone data usage
sudo convert ${DIR_PICTURES}/${imageFilename} -resize 640 /tmp/mini_${imageFilename}
if [ -f ${DIR_PICTURES}/${diffFile} ] ; then
   sudo convert ${DIR_PICTURES}/${diffFile}   -resize 320 /tmp/mini_${diffFile}
fi
if [ ! -f /tmp/mini_${imageFilename} ] ; then
   f_trace "ERROR File not found: /tmp/mini_${imageFilename}"
fi


# --- send it by email

# enable internet conection
#f_trace "ps wvdial: $(ps -ef | grep -v 'grep' | grep wvdial)"
isProcessRunning=$(ps -ef | grep -v "grep" | grep "wvdial" | wc -l | xargs echo)
f_trace "nb wvdial Process Running=$isProcessRunning"
if [ $isProcessRunning -eq 0 ]; then
  f_trace "start wvdial..."
  wvdial &
  sleep 5
fi

f_trace "send email alert to $destEmail"
cp ${DIR_PICTURES}/${imageFilename} ${DIR_SENT_PICTURES}/${imageFilename}

mailMsg="BigBro a detecte une activite suspecte le $(date '+%Y-%m-%d %T') !"
mailSubject="WARNING Barcelo : activite suspecte ${latestEvent}"
[ -f /tmp/mini_${imageFilename} ] && mailArgs="${mailArgs} --attach=/tmp/mini_${imageFilename}"
[ -f /tmp/mini_${diffFile} ]      && mailArgs="${mailArgs} --attach=/tmp/mini_${diffFile}"

echo "${mailMsg}" | mail ${mailArgs} -s "$mailSubject" $destEmail
retCode=$?
if [[ $retCode -ne 0 ]] ; then
  f_trace "mail FAILED retCode=$retCode"
fi

#sudo rm /tmp/mini_*

f_exit 0

# the end.



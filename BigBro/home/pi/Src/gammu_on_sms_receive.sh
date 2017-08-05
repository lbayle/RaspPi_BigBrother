#!/bin/bash
##################################################################
# Author: LoB 2017-08-05
##################################################################
#
#  --- WARNING ---
#  Do not forget to set the SIM-Card PIN code !
#  ... Or you'll block your SIM-Card immediately.
#  Be sure you have your PUK code before you start.
#
#  Set it here: /etc/gammu-smsdrc
#
##################################################################
#
# SMS text format = "<password> <cmd> <arg1>"
#
# BigBro sms actions:
#    <cmd>  <arg1>
#  - camera start
#  - camera stop
#  - camera snapshot
#  - bigbro status
#  - bigbro cleanup (admin only)
#  - bigbro reboot  (admin only)
#
# gammu configuration:
# sudo vi /etc/gammu-smsdrc
# RunOnReceive = /home/pi/Src/on_sms_receive.sh
#
# /etc/sudoers:
# www-data ALL=(ALL) NOPASSWD: /usr/bin/gammu-smsd-inject
# gammu    ALL=(ALL) NOPASSWD: /usr/bin/gammu-smsd-inject
# gammu    ALL=(ALL) NOPASSWD: /usr/bin/raspistill
# gammu    ALL=(ALL) NOPASSWD: /usr/bin/motion
# gammu    ALL=(ALL) NOPASSWD: /sbin/reboot
# gammu    ALL=(ALL) NOPASSWD: /bin/kill
# gammu    ALL=(ALL) NOPASSWD: /usr/bin/pkill motion
#
#
##################################################################

PHONE_BIGBRO="+336xxxxxxxx" # RaspberryPi dongle

PHONE_ADMIN1="+336xxxxxxxx" # Louis
PHONE_ADMIN2="+94xxxxxxxxx" # Francoise (SriLanka)

declare -A PASSWORDS=(
   ["${PHONE_ADMIN1}"]="xxxxx"       # Louis
   ["${PHONE_ADMIN2}"]="xxxxx"       # Francoise
   ["+336xxxxxxxx"]="xxxxx"          # Margrit B
   ["+336xxxxxxxx"]="xxxxx"          # Philippe B
   ["+336xxxxxxxx"]="xxxxx"          # Mimi
   ["+336xxxxxxxx"]="xxxxx"          # Vero
   ["+336xxxxxxxx"]="xxxxx"          # gaelle
   )

declare -A EMAILS=(
   ["${PHONE_ADMIN1}"]="louis.bayle@gmail.com"   # Louis
   ["${PHONE_ADMIN2}"]="xxxxxx@gmail.com"        # Francoise
   ["+336xxxxxxxx"]="xxxxxx@gmail.com"           # Margrit B
   ["+336xxxxxxxx"]="xxxxxx@gmail.com"           # Philippe B
   ["+336xxxxxxxx"]="xxxxxx@gmail.com"           # Mimi
   ["+336xxxxxxxx"]="xxxxxx@gmail.com"           # Vero
   ["+336xxxxxxxx"]="xxxxxx@gmail.com"           # gaelle
   )


##################################################################


MY_PID=$$
MY_FILENAME=$(basename "$0")
MY_FILENAME_NO_EXT=$(basename "$0" .sh)  # filename without extension

DIR_IMG="/var/www/html/images/camera/captures"
INBOX="/var/spool/gammu/inbox"

LOG_FILE="/data/log/bigbro_global_activity.log"
LOG_GAMMU_FILE="/data/log/gammu-smsd.log"

MOTION_CONF_FILE="/etc/motion/motion.conf"
MOTION_PID_FILE="/var/run/motion/motion.pid"

SNAPSHOT_FILE=${DIR_IMG}/snapshots/snapshot_$(date '+%Y%m%d_%Hh%M').jpg

##################################################################
## FUNCTIONS
##################################################################

# --------------------------------------------------------
# usage : f_trace [NO_DATE] "<message>"
f_trace () {

  if [ "xNO_DATE"  = "x$1" ] ; then
    local trace="[${USER}::${MY_FILENAME}] $2"
  else
    local trace="$(date '+%Y-%m-%d %T') [${USER}::${MY_FILENAME}] $1"
  fi
  echo $trace
  echo $trace >> $LOG_FILE
}

# --------------------------------------------------------
# usage: f_checkRetCode <retCode> <expected> <exitCode> [NO_EXIT]
# exemple: f_checkRetCode $? 0 128
# exemple: f_checkRetCode $? 0 128 NO_EXIT
f_checkRetCode () {
  local retCode=$1
  local expected=$2
  local exitCode=$3
  local noExit=$4

  if [ $retCode != $expected ]
  then
    NB_ERR=$(($NB_ERR + 1))
    if [ "x$noExit" != "xNO_EXIT" ] ; then
      f_trace NO_DATE "ERROR [${USER}::${MY_FILENAME}] (retCode=$retCode exitCode=$exitCode)"
      f_trace NO_DATE "log file: $LOG_FILE"
      exit $exitCode
    else
      f_trace NO_DATE "ERROR, (retCode=$retCode exitCode=$exitCode)"
    fi
  else
    f_trace NO_DATE "OK"
  fi
}

# --------------------------------------------------------
# usage: f_send_email <subject> <text> <user@gmail.com> [<attach_filename>]
f_send_email () {
   local emailSubject=$1
   local emailText=$2
   local emailAddress=$3
   local emailFile=$4

   local mailArgs="";
   [ -f ${emailFile} ] && mailArgs="${mailArgs}--attach=${emailFile}"

   # TODO HTML message
   # TODO add BigBro instructions (SMS format & allowed actions)

   echo "${emailText}" | mail -s "${emailSubject}" ${mailArgs} ${emailAddress} >> $LOG_FILE 2>&1
   f_checkRetCode $? 0 40 NO_EXIT
}

# --------------------------------------------------------
f_send_sms () {
   local phoneNumber="$1"
   local smsMessage="$2"
   sudo gammu-smsd-inject TEXT ${phoneNumber} -text "${smsMessage}" >> /dev/null 2>&1
}

# --------------------------------------------------------
# start surveillnce
# send status SMS to sender & Admin
f_motion_start () {

  # check if already running
  [ -f ${MOTION_PID_FILE} ] && motionPID=$(cat ${MOTION_PID_FILE}) || motionPID="not_found"
  ps -p ${motionPID} > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
     f_trace "Action: motion start"
     sudo motion -c ${MOTION_CONF_FILE} >> $LOG_FILE 2>&1
     f_checkRetCode $? 0 10 NO_EXIT
     smsMsg="BigBro motion started !"
  else
     smsMsg="BigBro motion already running (PID=${motionPID}) !"
  fi

  f_trace "Action: send SMS to BigBro Administrator & ${SMS_1_NUMBER}"
  f_send_sms ${PHONE_ADMIN1} "${smsMsg}"
  f_checkRetCode $? 0 11 NO_EXIT
  sleep 1
  f_send_sms ${SMS_1_NUMBER} "${smsMsg}"
  f_checkRetCode $? 0 12 NO_EXIT

}

# --------------------------------------------------------
# stop surveillance
# send status SMS to sender & Admin
f_motion_stop () {
  f_trace "Action: motion stop"

  [ -f ${MOTION_PID_FILE} ] && motionPID=$(cat ${MOTION_PID_FILE}) || motionPID="not_found"
  sudo kill $motionPID >> $LOG_FILE 2>&1
  sudo pkill motion

  f_trace "Action: send SMS to BigBro Administrator & ${SMS_1_NUMBER}"
  f_send_sms ${PHONE_ADMIN1} "BigBro motion stopped !"
  f_checkRetCode $? 0 20 NO_EXIT
  sleep 1
  # TODO send 2nd sms only if ${SMS_1_NUMBER} != ${PHONE_ADMIN1}
  f_send_sms ${SMS_1_NUMBER} "BigBro motion stopped !"
  f_checkRetCode $? 0 21 NO_EXIT

  sleep 5
}

# --------------------------------------------------------
# takes an image from the camera
# motion must be stopped to take a picture
f_camera_snapshot () {
   f_trace "Action: take camera snapshot : ${SNAPSHOT_FILE}"

  # stop motion if running ($MOTION_PID_FILE exists)
  # check if already running
  [ -f ${MOTION_PID_FILE} ] && motionPID=$(cat ${MOTION_PID_FILE}) || motionPID="not_found"
  ps -p ${motionPID} > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
     f_trace "Action: motion must be stopped before taking a snapshot..."
     sudo kill $(cat ${MOTION_PID_FILE}) >> $LOG_FILE 2>&1
     sudo pkill motion
     local isMotionStart=1
  fi

   # take snapshot
   sudo raspistill -w 1280 -h 720 -o ${SNAPSHOT_FILE} >> $LOG_FILE 2>&1
   f_checkRetCode $? 0 30
   f_send_sms ${SMS_1_NUMBER} "BigBro snapshot saved."

   # restart motion if previously running
  if [ "${motionPID}" != "not_found" ] ; then
     f_trace "Action: motion must be restarted after snapshot..."
     f_motion_start
  fi
}


##################################################################
## MAIN
##################################################################

f_trace "----------------------------------------------------------"

# For debug purpose only (there are no cmd-line args when script is called from gammu-smsd)
if [ $# -eq 2 ] ; then
   f_trace "Debug mode (executed from command line)"
   SMS_1_NUMBER="$1"
   SMS_1_TEXT="$2"
fi

f_trace "PHONE=${SMS_1_NUMBER} SMS_TEXT='${SMS_1_TEXT}'"

# --- read SMS text (format = '<password> <cmd> <arg1>')
myPassword=$(echo "${SMS_1_TEXT}" | cut -f1 -d' ');
myAction=$(echo "${SMS_1_TEXT}" | cut -f2 -d' ');
myArg1=$(echo "${SMS_1_TEXT}" | cut -f3 -d' ');

# --- check sender/password
isAdmin=0
if [ "${PASSWORDS[${SMS_1_NUMBER}]}" != "${myPassword}" ] ; then
   f_trace "Password ${myPassword} is wrong for ${SMS_1_NUMBER}"

   # warn Admin that an unallowed sms was received (send sms text & phone number)
   f_send_sms ${PHONE_ADMIN1} "WARN bigbro wrong password SMS_TEXT='${SMS_1_TEXT}' (${SMS_1_NUMBER})"
   f_checkRetCode $? 0 53
   exit 1
else
   f_trace "Password correct for ${EMAILS[${SMS_1_NUMBER}]}"
   if [ "${SMS_1_NUMBER}" == "${PHONE_ADMIN1}" ] || [ "${SMS_1_NUMBER}" == "${PHONE_ADMIN2}" ] ; then
      isAdmin=1
   fi
fi

# ----- HANDLE ACTIONS -----
myCommand=$(echo "${myAction} ${myArg1}" | awk '{print tolower($0)}')
f_trace "myCommand=$myCommand"

case "${myCommand}" in
# -------------
("bigbro help")
   helpMsg="BigBro actions: camera start, camera stop, camera snapshot, bigbro status"
   [ ${isAdmin} -eq 1 ] && helpMsg="${helpMsg}, bigbro cleanup, bigbro reboot"
   f_send_sms ${SMS_1_NUMBER} "${helpMsg}"
   f_checkRetCode $? 0 51
   ;;

# -------------
("bigbro status")
   statusMsg="BigBro status: "

   # check sysdate
   statusMsg="${statusMsg} sysdate=$(date '+%Y-%m-%d %T')"

   # check HD usage
   diskusage=($(df -k --output=pcent .))
   statusMsg="${statusMsg} diskUsage=${diskusage[1]}"

   # check motion started
   if [ ! -f ${MOTION_PID_FILE} ] ; then
      statusMsg="${statusMsg}, camera not recording"
   else
      motionPID=$(cat ${MOTION_PID_FILE})
      ps -p ${motionPID} > /dev/null 2>&1
      if [ $? -eq 0 ] ; then
         statusMsg="${statusMsg}, camera recording (PID=${motionPID})"
      else
         statusMsg="${statusMsg}, camera not recording !"
      fi
   fi

   f_trace "SMS send to ${SMS_1_NUMBER}: ${statusMsg}"
   f_send_sms ${SMS_1_NUMBER} "${statusMsg}"
   f_checkRetCode $? 0 52
   ;;

# -------------
("bigbro reboot")
   if [ ${isAdmin} -eq 1 ] ; then
      f_trace "BigBro reboot (${SMS_1_NUMBER})"
      #f_send_sms ${SMS_1_NUMBER} "bigbro reboot !"
      #f_checkRetCode $? 0 53
      sleep 5
      sudo reboot
   else
      f_trace "WARN User not admin: reboot FORBIDDEN (${SMS_1_NUMBER})"
      #f_send_sms ${PHONE_ADMIN1} "WARN bigbro reboot attempt (${SMS_1_NUMBER})"
      #f_checkRetCode $? 0 53
   fi
   ;;

# -------------
("bigbro cleanup")
   if [ ${isAdmin} -eq 1 ] ; then
      # --- delete pictures from $DIR_IMG to free HD usage
      # motion.conf: on_picture_save chmod a+rw %f
      rm -f $DIR_IMG/*.jpg >> $LOG_FILE 2>&1

      # --- delete history from MySQL bigbro_gammu DB
      mysql -e "DELETE FROM sentitems" --user=gammu --password=gammu bigbro_gammu
      mysql -e "DELETE FROM inbox" --user=gammu --password=gammu bigbro_gammu

      # --- send status SMS
      diskusage=($(df -k --output=pcent .))
      cleanupMsg="BigBro cleanup done: diskUsage=${diskusage[1]}"
      f_trace "${cleanupMsg}"
      f_send_sms ${SMS_1_NUMBER} "${cleanupMsg}"
      f_checkRetCode $? 0 52
   else
      f_trace "WARN User not admin: cleanup FORBIDDEN (${SMS_1_NUMBER})"
      #f_send_sms ${PHONE_ADMIN1} "WARN bigbro cleanup attempt (${SMS_1_NUMBER})"
      #f_checkRetCode $? 0 53
   fi
   ;;

# -------------
("camera start")
   f_motion_start
   ;;
# -------------
("camera stop")
   f_motion_stop
   ;;
# -------------
("camera snapshot")
   f_camera_snapshot

   destEmail="${EMAILS[${SMS_1_NUMBER}]}"
   #destEmail="${EMAILS[${SMS_1_NUMBER}]},${EMAILS[${PHONE_ADMIN1}]}"
   #destEmail=louis.bayle@gmail.com,lbayle.trash@gmail.com
   f_trace "Action: send snapshot per email to $destEmail"
   f_send_email "BigBro snapshot" "<b>File:</b> ${SNAPSHOT_FILE}" ${destEmail} ${SNAPSHOT_FILE}
   ;;

# -------------
(*)
   f_trace "ERROR unknown action: (${SMS_1_NUMBER}) ${myCommand}"
   # prevent loop SMS if sending SMS from Raspbery
   if [ "${SMS_1_NUMBER}" != "${PHONE_BIGBRO}" ] ; then
      f_send_sms ${PHONE_ADMIN1} "BigBro unknown action: (${SMS_1_NUMBER}) ${myCommand}"
   fi
   ;;
esac


# The End.

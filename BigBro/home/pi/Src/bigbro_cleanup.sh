#!/bin/bash
# LoB 2017-08-06 


MY_PID=$$
MY_FILENAME=$(basename "$0")
MY_FILENAME_NO_EXT=$(basename "$0" .sh)  # filename without extension

DIR_IMG="/var/www/html/images/camera/captures"
INBOX="/var/spool/gammu/inbox"
LOG_FILE="/data/log/bigbro_global_activity.log"


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

##################################################################
## MAIN
##################################################################

diskusage=($(df -k --output=pcent .))
cleanupMsg="BigBro diskUsage=${diskusage[1]}"
f_trace "${cleanupMsg}"

# --- delete pictures from $DIR_IMG to free HD usage
# motion.conf: on_picture_save chmod a+rw %f
rm -f $DIR_IMG/*.jpg >> $LOG_FILE 2>&1

# --- delete history from MySQL bigbro_gammu DB
mysql -e "DELETE FROM sentitems" --user=gammu --password=gammu bigbro_gammu
mysql -e "DELETE FROM inbox" --user=gammu --password=gammu bigbro_gammu


# TODO clean logs ?
#> $LOG_FILE

diskusage=($(df -k --output=pcent .))
cleanupMsg="BigBro cleanup done: diskUsage=${diskusage[1]}"
f_trace "${cleanupMsg}"



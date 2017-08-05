#!/bin/bash
# LoB

MY_PID=$$
MY_FILENAME=$(basename "$0")
MY_FILENAME_NO_EXT=$(basename "$0" .sh)  # filename without extension

LOG_FILE="/data/log/bigbro_global_activity.log"
DIR_PICTURES="/var/www/html/images/camera"

##################################################################
## TOOLS
##################################################################

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


##################################################################
## MAIN
##################################################################

f_trace "event_start !"

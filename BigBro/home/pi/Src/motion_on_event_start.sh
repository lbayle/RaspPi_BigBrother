#!/bin/bash
# LoB
# An event has been detected, now we want to be sure that gammu & wvdial
# are running, to be able to send SMS & email alerts when event ends.

# motion has been configured to wait for 15s inactivity before running motion_on_event_end.sh
# so we have a fiew seconds to restart processes

# +CME ERROR: 11 => Sim PIN required
# +CME ERROR: 12 => Sim PUK required


MY_PID=$$
MY_FILENAME=$(basename "$0")
MY_FILENAME_NO_EXT=$(basename "$0" .sh)  # filename without extension

LOG_FILE="/data/log/bigbro_global_activity.log"

##################################################################
## TOOLS
##################################################################

# --------------------------------------------------------
# usage : f_trace [NO_DATE] "<message>"
function f_trace {

  if [ "xNO_DATE"  = "x$1" ] ; then
    local trace="[$(whoami)::${MY_FILENAME}] $2"
  else
    local trace="$(date '+%Y-%m-%d %T') [$(whoami)::${MY_FILENAME}] $1"
  fi
  echo $trace
  echo $trace >> $LOG_FILE
}


##################################################################
## MAIN
##################################################################

f_trace "event_start !"

#isProcessRunning=$(ps -ef | grep -v "grep" | grep "wvdial"  | grep -v 'sudo' | grep -v 'tail' | wc -l | xargs echo)
#f_trace "nb wvdial Process Running=$isProcessRunning"

wvdial_pid=$(ps -ef | grep wvdial | grep -v 'pppd' | grep -v 'sudo' | grep -v 'grep' | grep -v 'tail' | awk '{print $2}')
ppp_pid=$(ps -ef    | grep wvdial | grep    'pppd' | grep -v 'sudo' | grep -v 'grep' | grep -v 'tail' | awk '{print $2}')

[ "${wvdial_pid}x" == 'x' ] && f_trace "WARNING: wvdial is not running !"
[ "${ppp_pid}x" == 'x' ]    && f_trace "ERROR  : pppd   is not running !"

#if [ "${wvdial_pid}x" == 'x' ] || [ "${ppp_pid}x" == 'x' ] ; then
if [ "${ppp_pid}x" == 'x' ] ; then

  [ "${wvdial_pid}x" != 'x' ] && kill -9 ${wvdial_pid}

  f_trace "run wvdial pin ..."
  wvdial pin >> /data/log/wvdial.log 2>&1
  f_trace "restart wvdial freeMobile ..."
  #wvdial Defaults >> /data/log/wvdial.log 2>&1 &
  wvdial freeMobile >> /data/log/wvdial.log 2>&1 &
  sleep 5
  f_trace "ps wvdial    : $(ps -ef | grep -v 'grep' | grep 'wvdial' | grep -v 'ppp' | grep -v 'sudo' | grep -v 'tail' )"
  f_trace "ps wvdial ppp: $(ps -ef | grep -v 'grep' | grep 'wvdial' | grep 'ppp' | grep -v 'tail' )"
fi


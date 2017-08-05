#!/bin/bash
# LoB 2017-08-05
# cree une archive de tous les fichiers de config modifies sur BigBro
# => contenant le tag "LoB"

CUR_DIR="$(pwd)"
BASE_DIR=/root/BigBroArchive
FILE_CFG_LIST=${BASE_DIR}/configfiles.txt
FILE_TRACE=/tmp/${MY_FILENAME_NO_EXT}.txt
FILE_ARCHIVE=/root/bigBroArchive_$(date '+%y%m%d').tgz
#FILE_ARCHIVE=${CUR_DIR}/bigBroArchive_$(date '+%y%m%d').tgz



# --------------------------------------------------------
# ecrit une log sur stdout et dans FILE_TRACE
# usage : f_trace [NO_DATE] "<message>"
function f_trace {

  if [ "xNO_DATE"  == "x$1" ] ; then
    local trace="$2"
  else
    local trace="$(date '+%d/%m/%y %T') $1"
  fi
  echo $trace
  echo $trace >> $FILE_TRACE
}

# =======================================================================
# MAIN
# =======================================================================

> $FILE_TRACE
rm -rf ${BASE_DIR}
rm ${FILE_ARCHIVE}
mkdir -p ${BASE_DIR}

# ---------------------------------
# get modified config files from various places
find /etc               -name "*" | xargs grep -l "LoB" > /tmp/configfiles.txt
find /var/www/html      -name "*" | xargs grep -l "LoB" >> /tmp/configfiles.txt
find /home/pi/Src       -name "*" | xargs grep -l "LoB" >> /tmp/configfiles.txt
find /home/pi/Documents -name "*" | xargs grep -l "LoB" >> /tmp/configfiles.txt
find /root/Src          -name "*" | xargs grep -l "LoB" >> /tmp/configfiles.txt

sort -u /tmp/configfiles.txt -o ${FILE_CFG_LIST}
rm /tmp/configfiles.txt

# ---------------------------------
# process each file of the list
exec 9< ${FILE_CFG_LIST} # assign file descriptor 9 to file
while read -u 9 myCfgFile; do # read from file descriptor 9
    echo "line=${myCfgFile}"

    # create mirror tree with symlinks
    my_dirname=$(dirname ${myCfgFile})
    my_filename=$(basename ${myCfgFile})
    mkdir -p ${BASE_DIR}/${my_dirname}
    ln -s ${myCfgFile} --target-directory=${BASE_DIR}/${my_dirname}

done
exec 9<&- # free file descriptor 9

# ---------------------------------
# archive (follow symlinks)
tar cvzfh ${FILE_ARCHIVE} ${BASE_DIR}

echo "-------------"
echo "Archive:  ${FILE_ARCHIVE}"
echo ' '

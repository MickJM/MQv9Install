#!/bin/sh
#
function untarMQ() {
    #
    echo "Untaring MQ binary files ...." 
    #
    eval `grep mqSourceDir ${INI_FILE}`
    if [ -z ${mqSourceDir} ]; then
       echo "Invalid parameter; mqSourceDir is missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqSourceFile ${INI_FILE}`
    if [ -z ${mqSourceFile} ]; then
       echo "Invalid parameter; mqSourceFile is missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqTargetDir ${INI_FILE}`
    if [ -z ${mqTargetDir} ]; then
       echo "Invalid parameter; mqTargetDir is missing from ${INI_FILE}"
       exit 1
    fi
    #
    if [ ! -d ${mqTargetDir} ]; then
       echo "Directory ${mqTargetDir} is missing ... creating"
       if ! su - mqm -c "mkdir ${mqTargetDir}"; then
          echo "Error creating ${mqTargetDir}"
          exit 1
       fi
    fi
    #    
    cd ${mqTargetDir}
    #
    if ! tar -xvf ${mqSourceDir}/${mqSourceFile}; then
       echo "Error extracting tar file ${mqSourceDir}/${mqSourceFile}"
       exit 1
    fi
    #
    cd MQServer
    ./mqlicense.sh -accept
    #
    echo "Current MQ series installed packages ...."
    rpm -qa | grep MQSeries
    #
    RC=$?
    #
}
#

####################
# Main section
#
####################
    echo "Starting untarMQv9 ...."
    #
    RC=0
    #
    if (($EUID != 0 )); then
       echo "The script must be run as root"
       exit 1
    fi
#
    INI_FILE=$1
    if [ -z ${INI_FILE} ]; then
       echo "Script called with incorrect number of parameters"
       exit 1
    fi
    if [ ! -f ${INI_FILE} ]; then
       echo "INI_FILE can not be found"
       exit 1
    fi
#
# Untar file
#
    untarMQ
    RC=$?
#
#
exit ${RC}

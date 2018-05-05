#!/bin/sh
#
function installMQv9Part1() {
    #
    echo "Installing MQv9 ...." 
    #
    eval `grep mqTargetDir ${INI_FILE}`
    if [ -z ${mqTargetDir} ]; then
       echo "Invalid parameter; mqTargetDir is missing from ${INI_FILE}"
       exit 1
    fi
    #
    mqUnzipped="${mqTargetDir}/MQServer/"
    #
    echo "Current MQSeries installed packages ...."
    rpm -qa | grep MQSeries
    if [ ! -d ${mqUnzipped} ]; then
       echo "Directory ${mqUnzipped} is missing, unzip MQ files"
       exit 1
    fi
    #
    cd ${mqUnzipped}
    ./mqlicense.sh -accept
    #
    echo "Installing MQSeriesRuntime and MQSeriesServer"
    if ! rpm -ivh MQSeriesRuntime-*.rpm MQSeriesServer-*.rpm; then
       echo "Error installing MQSeriesRuntime or MSeriesServer"
       exit 1
    fi
    #
    echo "/opt/mqm/bin/mqconfig ...."
    su mqm -c "/opt/mqm/bin/mqconfig"
    failed=$(su mqm -c "/opt/mqm/bin/mqconfig" | grep FAIL | wc -l)
    if [ "${failed}" -ne "0" ]; then
       echo "System parameters are in error"
       exit 1
    fi
    #
    # ./mqlicense.sh -accept
    #
    echo "Current MQ series installed packages ...."
    rpm -qa | grep MQSeries
    #
    RC=$?
    #
}
###################
# Install MQv9 Part 2
##################
function installMQv9Part2() {
    #
    # Install remaining packages
    #
    echo "/opt/mqm/bin/mqconfig ...."
    su mqm -c "/opt/mqm/bin/mqconfig"
    failed=$(su mqm -c "/opt/mqm/bin/mqconfig" | grep FAIL | wc -l)
    if [ "${failed}" -ne "0" ]; then
       echo "System parameters are in error"
       exit 1
    fi
    #
    ./mqlicense.sh -accept
    #
    echo "Current MQ series installed packages ...."
    rpm -qa | grep MQSeries
    #
    echo "Installing remaining packages ...."
    eval `grep mqTargetDir ${INI_FILE}`
    if [ -z ${mqTargetDir} ]; then
       echo "Invalid parameter; mqTargetDir is missing from ${INI_FILE}"
       exit 1
    fi
    #
    mqUnzipped="${mqTargetDir}/MQServer/"
    #
    if [ ! -d ${mqUnzipped} ]; then
       echo "Directory ${mqUnzipped} is missing, unzip MQ files"
       exit 1
    fi
    #
    cd ${mqUnzipped}
    echo "Installing MQSeriesClient"
    if ! rpm -ivh MQSeriesClient-*.rpm; then
       echo "Error installing MQSeriesClient-*"
       exit 1
    fi
    echo "Installing MQSeriesSDK"
    if ! rpm -ivh MQSeriesSDK-*.rpm; then
       echo "Error installing MQSeriesSDK-*"
       exit 1
    fi
    echo "Installing MQSeriesSamples"
    if ! rpm -ivh MQSeriesSamples-*.rpm; then
       echo "Error installing MQSeriesSamples-*"
       exit 1
    fi
    #
    # Java / JRE must be installed before XRService
    # Java must be installed before JRE
    # 
    echo "Installing MQSeriesJava"
    if ! rpm -ivh MQSeriesJava-*.rpm; then
       echo "Error installing MQSeriesJava-*"
       exit 1
    fi
    echo "Installing MQSeriesJRE"
    if ! rpm -ivh MQSeriesJRE-*.rpm; then
       echo "Error installing MQSeriesJRE-*"
       exit 1
    fi
    echo "Installing MQSeriesXRService"
    if ! rpm -ivh MQSeriesXRService-*.rpm; then
       echo "Error installing MQSeriesXRService-*"
       exit 1
    fi
    echo "Installing MQSeriesMan"
    if ! rpm -ivh MQSeriesMan-*.rpm; then
       echo "Error installing MQSeriesMan-*"
       exit 1
    fi
    echo "Installing MQSeriesGSKit"
    if ! rpm -ivh MQSeriesGSKit-*.rpm; then
       echo "Error installing MQSeriesGSKit-*"
       exit 1
    fi
    echo "Installing MQSeriesAMS"
    if ! rpm -ivh MQSeriesAMS-*.rpm; then
       echo "Error installing MQSeriesAMS-*"
       exit 1
    fi
    #
    # Dont bother with MQ explorer 
    #
    #echo "Installing MQSeriesExplorer"
    #if ! rpm -ivh MQSeriesExplorer-*.rpm; then
    #   echo "Error installing MQSeriesExplorer-*"
    #   exit 1
    #fi
    #
    mqmDir=/home/mqm
    pathLine=$(cat ${mqmDir}/.bash_profile | grep PATH= -n)
    if [ -z ${pathLine} ]; then
       echo "Error 'Path=' variable not found in ${mqmDir}"
       exit 1
    fi
    lineNo=$(echo ${pathLine} | awk -F ":" '{print $1}')
    lineNo=$( expr ${lineNo} - 1 )
    sed -i "${lineNo}i# Auto inserted by installMQ.sh script\n. /opt/mqm/bin/setmqenv -s " ${mqmDir}/.bash_profile    


}

####################
# Main section
#
####################
    echo "Starting installMQv9 ...."
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
# Install MQ
#
    RC=0
   # installMQv9Part1
    RC=$?
    installMQv9Part2
    RC=$?
#
#
exit ${RC}

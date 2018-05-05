#!/bin/sh
#
function createPartitions() {
    #
    # Partition disk 
    #
    eval `grep disk ${INI_FILE}`
    if [ -z ${disk} ]; then
       echo "Invalid parameter; disk is missing from ${INI_FILE}"
       exit 1
    fi 
    #
    correctDisk=`lsblk --fs | grep ${disk} | grep /mnt | wc -l`
    if [ ${correctDisk} != 0 ]; then
       echo "Disk ${disk} is already mounted"
       exit 1
    fi
    echo "Disk ${disk} is not currently mounted ..."
    #
    p=`fdisk -l /dev/${disk} | grep ${disk} | wc -l`
    if [ ${p} != 1 ]; then
       echo "Existing partions exist on /dev/${disk} ... please remove"
       exit 1
    fi
    echo "No partions exists on disk ${disk}"
    #
    fdisk /dev/${disk} << EOF
p
n
p



w
EOF
    #
    RC=$?
    fdisk -l
}
#
# createVolumeGroups
#  rpa -qa | grep -i lvm
#  yum install lvm2*
#
function createVolumeGroups() {
    echo "Creating volume groups ...."
    #
    eval `grep disk ${INI_FILE}`
    if [ -z ${disk} ]; then
       echo "Invalid parameter; disk is missing from ${INI_FILE}"
       exit 1
    fi
    #
    eval `grep partSize1 ${INI_FILE}`
    if [ -z ${partSize1} ]; then
       echo "Invalid parameter; partSize1 is missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep partSize2 ${INI_FILE}`
    if [ -z ${partSize2} ]; then
       echo "Invalid parameter; partSize2 is missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep partSize3 ${INI_FILE}`
    if [ -z ${partSize3} ]; then
       echo "Invalid parameter; partSize3 is missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep partSize4 ${INI_FILE}`
    if [ -z ${partSize4} ]; then
       echo "Invalid parameter; partSize4 is missing from ${INI_FILE}"
       exit 1
    fi
    #
    if ! vgcreate lv_mqm /dev/${disk}1; then
       echo "Error creating Volume group lv_mqm"
       exit 1
    fi
    if ! lvcreate lv_mqm -L ${partSize1} --name qmgrs; then
       echo "Error creating Logical volume for qmgrs"
       exit 1
    fi
    if ! lvcreate lv_mqm -L ${partSize2} --name log; then
       echo "Error creating Logical volume for log"
       exit 1
    fi
    if ! lvcreate lv_mqm -L ${partSize3} --name errors; then
       echo "Error creating Logical volume for errors"
       exit 1
    fi
    if ! lvcreate lv_mqm -L ${partSize4} --name trace; then
       echo "Error creating Logical volume for trace"
       exit 1
    fi
    #
    echo "Logical volums created ..."

}
#
# formatPartitions
#
function formatPartitions() {
    #
    echo "Formating partitions ...."
    #
    if ! mkfs.ext4 -L qmgrs /dev/mapper/lv_mqm-qmgrs; then
       echo "Error formatting /dev/mapper/lv_mqm-qmgrs"
       exit 1
    fi   
    if ! mkfs.ext4 -L log /dev/mapper/lv_mqm-log; then
       echo "Error formatting /dev/mapper/lv_mqm-log"
       exit 1
    fi
    if ! mkfs.ext4 -L errors /dev/mapper/lv_mqm-errors; then
       echo "Error formatting /dev/mapper/lv_mqm-errors"
       exit 1
    fi
    if ! mkfs.ext4 -L trace /dev/mapper/lv_mqm-trace; then
       echo "Error formatting /dev/mapper/lv_mqm-trace"
       exit 1
    fi
}
###################
# Create mqm user / group
###################
function createCredentials() {
    #
    echo "Cretaing MQ user / group"
    #
    eval `grep mqGroup ${INI_FILE}`
    if [ -z ${mqGroup} ]; then
       echo "Invalid parameter; mqGroup misssing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqUserId ${INI_FILE}`
    if [ -z ${mqUserId} ]; then
       echo "Invalid parameter; mqUserId misssing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqPasswd ${INI_FILE}`
    if [ -z ${mqPasswd} ]; then
       echo "Invalid parameter; mqPasswd misssing from ${INI_FILE}"
       exit 1
    fi
    #
    if groups ${mqGroup}; then
       echo "MQ ${mqGroup} group already exists"
    else
       echo "MQ ${mqGroup} does not exist, creating ..."
       if ! groupadd ${mqGroup}; then
           echo "Failed to create MQ group ${mqGroup}"
           exit 1
       fi
    fi
    #
    if id ${mqUserId}; then
       echo "MQ ${mqUserId} user already exists"
    else
       echo "MQ ${mqUserId} does not exist, creating ..."
       if ! useradd ${mqGroup} ${mqUserId}; then
           echo "Failed to create MQ user ${mqUserId}"
           exit 1
       fi
    fi
    #
    if ! echo ${mqPasswd} | passwd ${mqUserId} --stdin; then
       echo "Failed to set password for ${mqUserId}"
       exit 1
    fi

}
###################
# Add UUID to each partition to /etc/fstab
##################
function updatefstab() {
    #
    echo "Updating fstab"
    #
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'qmgrs' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/qmgrs/ \t ext4 \t defaults,nofail \t 1 2\n",$1}' >> /etc/fstab; then
       echo "Error adding qmgrs UUID to /etc/fstab"
       exit 1
    fi
    #
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'log' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/log/ \t ext4 \t defaults,nofail \t 1 2\n",$1}' >> /etc/fstab; then
       echo "Error adding log UUID to /etc/fstab"
       exit 1
    fi
    #
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'errors' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/errors/ \t ext4 \t defaults,nofail \t 1 2\n",$1}' >> /etc/fstab; then
       echo "Error adding errors UUID to /etc/fstab"
       exit 1
    fi
    #
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'trace' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/trace/ \t ext4 \t defaults,nofail \t 1 2\n",$1}' >> /etc/fstab; then
       echo "Error adding trace UUID to /etc/fstab"
       exit 1
    fi
    #
    echo "Successfully updated /etc/fstab"
    #

}

###################
# Create MQ folders
###################
function createMQFolders() {
    #
    echo "Creating MQ folders ..."
    #
    eval `grep mqGroup ${INI_FILE}`
    if [ -z ${mqGroup} ]; then
       echo "Invalid parameter; mqGroup misssing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqUserId ${INI_FILE}`
    if [ -z ${mqUserId} ]; then
       echo "Invalid parameter; mqUserId misssing from ${INI_FILE}"
       exit 1
    fi
    #
    if [ ! -e /var/mqm ]; then
        mkdir /var/mqm
        chown ${mqUserId}:${mqGroup} /var/mqm
    fi
    if [ ! -e /var/mqm/qmgrs ]; then
        mkdir -p /var/mqm/qmgrs
    #    chown ${mqUserId}:${mqGroup} /var/mqm/qmgrs
    fi
    if [ ! -e /var/mqm/log ]; then
        mkdir -p /var/mqm/log
    #    chown ${mqUserId}:${mqGroup} /var/mqm/log
    fi
    if [ ! -e /var/mqm/errors ]; then
        mkdir -p /var/mqm/errors
    #    chown ${mqUserId}:${mqGroup} /var/mqm/errors
    fi
    if [ ! -e /var/mqm/trace ]; then
        mkdir -p /var/mqm/trace
    #    chown ${mqUserId}:${mqGroup} /var/mqm/trace
    fi

}
###################
# Mount file systems
###################
function mountFileSystems() {
    #
    echo "Mounting file systems ...."
    #
    eval `grep mqGroup ${INI_FILE}`
    if [ -z ${mqGroup} ]; then
       echo "Invalid parameter; mqGroup misssing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqUserId ${INI_FILE}`
    if [ -z ${mqUserId} ]; then
       echo "Invalid parameter; mqUserId misssing from ${INI_FILE}"
       exit 1
    fi
    #
    if ! mount /dev/mapper/lv_mqm-qmgrs/ /var/mqm/qmgrs/;then
       echo "Error mounting /dev/mapper/lv_mqm-qmgrs/"
       exit 1 
    fi
    if ! mount /dev/mapper/lv_mqm-log/ /var/mqm/log/;then
       echo "Error mounting /dev/mapper/lv_mqm-log/"
       exit 1
    fi
    if ! mount /dev/mapper/lv_mqm-errors/ /var/mqm/errors/;then
       echo "Error mounting /dev/mapper/lv_mqm-errors/"
       exit 1
    fi
    if ! mount /dev/mapper/lv_mqm-trace/ /var/mqm/trace/;then
       echo "Error mounting /dev/mapper/lv_mqm-trace/"
       exit 1
    fi
    #
    echo "Mount successful"
    #
    # change owner
    #
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/qmgrs; then
        echo "Error chaning owner for /var/mqm/qmgrs"
    fi
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/log; then
        echo "Error chaning owner for /var/mqm/log"
    fi
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/errors; then
        echo "Error chaning owner for /var/mqm/errors"
    fi
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/trace; then
        echo "Error chaning owner for /var/mqm/trace"
    fi
    #
    echo "Owner change successful"
    #

}

####################
# Main section
#
####################
    echo "Starting partitions ...."
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
# Create partitions
#
#    createPartitions
    RC=$?
#
#
#
if [ ${RC} == 0 ]; then
   echo "Creating volume groups ...."
#   createVolumeGroups
   RC=$?
fi
#
if [ ${RC} == 0 ]; then
   echo "Formating partitions ...."
#   formatPartitions
   RC=$?
fi
#
if [ ${RC} == 0 ]; then
   echo "Creating MQ user / group"
#   createCredentials
   RC=$?
fi
#
if [ ${RC} == 0 ]; then
   echo "Creating MQ folder ...."
#   createMQFolders
   RC=$?
fi
#
if [ ${RC} == 0 ]; then
   echo "Mounting file systems ...."
#   mountFileSystems
   RC=$?
fi
#
if [ ${RC} == 0 ]; then
   echo "Updating /etc/fstab ...."
   updatefstab
   RC=$?
fi
#
exit ${RC}

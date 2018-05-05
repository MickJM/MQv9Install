#!/bin/sh
#
function updateSysctl() {
    #
    echo "Updating system files in /usr/lib/sysctl.d/99-override.conf ...." 
    #
    if [ -e /usr/lib/sysctl.d/99-override.conf ]; then
       echo " /usr/lib/sysctl.d/99-override.conf file exists ... removing"
       rm -f /usr/lib/sysctl.d/99-override.conf
    fi
    touch /usr/lib/sysctl.d/99-override.conf
    #
    if [ `grep "kernal.shmmni" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]; then
       echo "kernal.shmmni = 4096" >> /usr/lib/sysctl.d/99-override.conf
    else
       echo "kernal.shmmni already exists ...."
    fi
    #
    if [ `grep "kernal.shmall" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]; then
       echo "kernal.shmall = 2097152" >> /usr/lib/sysctl.d/99-override.conf
    else
       echo "kernal.shmall already exists ...."
    fi
    #
    if [ `grep "kernal.shmmax" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]; then
       echo "kernal.shmmax = 268435456" >> /usr/lib/sysctl.d/99-override.conf
    else
       echo "kernal.shmmax already exists ...."
    fi
    #
    if [ `grep "kernal.sem" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]; then
       echo "kernal.sem = 500 256000 250 1024" >> /usr/lib/sysctl.d/99-override.conf
    else
       echo "kernal.sem already exists ...."
    fi
    #
    if [ `grep "net.ipv4.tcp_keepalive_time" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]; then
       echo "net.ipv4.tcp_keepalive_time = 300" >> /usr/lib/sysctl.d/99-override.conf
    else
       echo "net.ipv4.tcp_keepalive_time already exists ...."
    fi
    #
    if [ `grep "fs.file-max" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]; then
       echo "fs.file-max = 524288" >> /usr/lib/sysctl.d/99-override.conf
    else
       echo "fs.file-max already exists ...."
    fi
    #
    # update threads-max
    #
    cat /proc/sys/kernel/threads-max
    echo 32768 > /proc/sys/kernel/threads-max
    #
    # overcommited_memory
    cat /proc/sys/vm/overcommit_memory
    echo 2 > /proc/sys/vm/overcommit_memory
    #
    if ! sysctl -p; then
       RC=$?
       echo "Error applying sysctl"
    fi
    #
    echo "System file updated ...."
    #
    RC=$?
    #
}
###################
# updateLimits
###################
function updateLimits() {
    #
    echo "Updating system limits ...."
    #
    if [ -e /etc/security/limits.d/99-mqm-limits.conf ]; then
       rm -f /etc/security/limits.d/99-mqm-limits.conf
    fi
    touch /etc/security/limits.d/99-mqm-limits.conf
    #
cat > /etc/security/limits.d/99-mqm-limits.conf << EOF
# Default limit for number of users processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning
# Auto created by updateSystemFile_mqm.sh

mqm        hard    nofile    10240
mqm        soft    nofile    10240 
mqm        hard    nproc     4096
mqm        soft    nproc     4096
EOF
    #
}

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
# Untar file
#
    updateSysctl
    updateLimits
    #
    RC=$?
    echo "MQ updateSysctl complete"
#
#
exit ${RC}

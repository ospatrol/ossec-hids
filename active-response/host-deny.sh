#!/bin/sh
# Adds an IP to the /etc/hosts.deny file
# Requirements: sshd and other binaries with tcp wrappers support
# Expect: srcip
# Author: Daniel B. Cid
# Last modified: Nov 09, 2005

ACTION=$1
USER=$2
IP=$3

LOCAL=`dirname $0`;
cd $LOCAL
cd ../
PWD=`pwd`
LOCK="${PWD}/host-deny-lock"
LOCK_PID="${PWD}/host-deny-lock/pid"
UNAME=`uname`


# This number should be more than enough (even if a hundred
# instances of this script is ran together). If you have
# a really loaded env, you can increase it to 75 or 100.
MAX_ITERATION="50"


# Lock function
lock()
{
    i=0;
    # Providing a lock.
    while [ 1 ]; do
        mkdir ${LOCK} > /dev/null 2>&1
        MSL=$?
        if [ "${MSL}" = "0" ]; then
            # Lock aquired (setting the pid)
            echo "$$" > ${LOCK_PID}
            return;
        fi

        # Getting currently/saved PID locking the file
        C_PID=`cat ${LOCK_PID} 2>/dev/null`
        if [ "x" = "x${S_PID}" ]; then
            S_PID=${C_PID}
        fi    

        # Breaking out of the loop after X attempts
        if [ "x${C_PID}" = "x${S_PID}" ]; then
            i=`expr $i + 1`;
        fi
   
        # Sleep 1 after 10/25 interactions
        if [ "$i" = "10" -o "$i" = "25" ]; then
            sleep 1;
        fi
             
        i=`expr $i + 1`;
        
        # So i increments 2 by 2 if the pid does not change.
        # If the pid keeps changing, we will increments one
        # by one and fail after MAX_ITERACTION
        if [ "$i" = "${MAX_ITERATION}" ]; then
            echo "`date` Unable to execute. Locked: $0" \
                        >> ${PWD}/ospatrol-hids-responses.log
            
            # Unlocking and exiting
            unlock;
            exit 1;                
        fi
    done
}

# Unlock function
unlock()
{
   rm -rf ${LOCK} 
}


# Logging the call
echo "`date` $0 $1 $2 $3 $4 $5" >> ${PWD}/../logs/active-responses.log


# IP Address must be provided
if [ "x${IP}" = "x" ]; then
   echo "$0: Missing argument <action> <user> (ip)" 
   exit 1;
fi


# Checking for invalid entries (lacking ".", etc)
echo "${IP}" | grep "\." > /dev/null 2>&1
if [ ! $? = 0 ]; then
    echo "`date` Invalid ip/hostname entry: ${IP}" >> ${PWD}/../logs/active-responses.log
    exit 1;
fi


# Adding the ip to hosts.deny
if [ "x${ACTION}" = "xadd" ]; then
   lock;     
   if [ "X$UNAME" = "XFreeBSD" ]; then
    echo "ALL : ${IP} : deny" >> /etc/hosts.allow
   else    
    echo "ALL:${IP}" >> /etc/hosts.deny
   fi 
   unlock;
   exit 0;


# Deleting from hosts.deny   
elif [ "x${ACTION}" = "xdelete" ]; then   
   lock;
   if [ "X$UNAME" = "XFreeBSD" ]; then
    cat /etc/hosts.allow | grep -v "ALL : ${IP} : deny$"> /tmp/hosts.deny.$$
    mv /tmp/hosts.deny.$$ /etc/hosts.allow
   else
    cat /etc/hosts.deny | grep -v "ALL:${IP}$"> /tmp/hosts.deny.$$
    cat /tmp/hosts.deny.$$ > /etc/hosts.deny
    rm /tmp/hosts.deny.$$
   fi 
   unlock;
   exit 0;


# Invalid action   
else
   echo "$0: invalid action: ${ACTION}"
fi       

exit 1;

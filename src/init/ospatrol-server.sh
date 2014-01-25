#!/bin/sh
# ospatrol-control        This shell script takes care of starting
#                      or stopping ospatrol-hids
# Author: Daniel B. Cid <daniel.cid@gmail.com>


# Getting where we are installed
LOCAL=`dirname $0`;
cd ${LOCAL}
PWD=`pwd`
DIR=`dirname $PWD`;
PLIST=${DIR}/bin/.process_list;


###  Do not modify bellow here ###

# Getting additional processes
ls -la ${PLIST} > /dev/null 2>&1
if [ $? = 0 ]; then
. ${PLIST};
fi


NAME="OSPatrol"
VERSION="v2.7.1"
AUTHOR="Jeremy Rossi"
DAEMONS="ospatrol-monitord ospatrol-logcollector ospatrol-remoted ospatrol-syscheckd ospatrol-analysisd ospatrol-maild ospatrol-execd ${DB_DAEMON} ${CSYSLOG_DAEMON} ${AGENTLESS_DAEMON}"


## Locking for the start/stop
LOCK="${DIR}/var/start-script-lock"
LOCK_PID="${LOCK}/pid"


# This number should be more than enough (even if it is
# started multiple times together). It will try for up
# to 10 attempts (or 10 seconds) to execute.
MAX_ITERATION="10"



# Check pid
checkpid()
{
    for i in ${DAEMONS}; do
        for j in `cat ${DIR}/var/run/${i}*.pid 2>/dev/null`; do
            ps -p $j |grep ospatrol >/dev/null 2>&1
            if [ ! $? = 0 ]; then
                echo "Deleting PID file '${DIR}/var/run/${i}-${j}.pid' not used..."
                rm ${DIR}/var/run/${i}-${j}.pid
            fi    
        done    
    done    
}



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

        # Waiting 1 second before trying again
        sleep 1;
        i=`expr $i + 1`;

        # If PID is not present, speed things a bit.
        kill -0 `cat ${LOCK_PID}` >/dev/null 2>&1
        if [ ! $? = 0 ]; then
            # Pid is not present.
            i=`expr $i + 1`;
        fi    

        # We tried 10 times to acquire the lock.
        if [ "$i" = "${MAX_ITERATION}" ]; then
            # Unlocking and executing
            unlock;
            mkdir ${LOCK} > /dev/null 2>&1
            echo "$$" > ${LOCK_PID}
            return;
        fi
    done
}


# Unlock function
unlock()
{
    rm -rf ${LOCK}
}

    
# Help message
help()
{
    # Help message
    echo ""
    echo "Usage: $0 {start|stop|restart|status|enable|disable}";
    exit 1;
}


# Enables/disables additional daemons
enable()
{
    if [ "X$2" = "X" ]; then
        echo ""
        echo "Enable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 enable [database|client-syslog|agentless|debug]"
        exit 1;
    fi
    
    if [ "X$2" = "Xdatabase" ]; then
        echo "DB_DAEMON=ospatrol-dbd" >> ${PLIST};
    elif [ "X$2" = "Xclient-syslog" ]; then
        echo "CSYSLOG_DAEMON=ospatrol-csyslogd" >> ${PLIST};
    elif [ "X$2" = "Xagentless" ]; then
        echo "AGENTLESS_DAEMON=ospatrol-agentlessd" >> ${PLIST};    
    elif [ "X$2" = "Xdebug" ]; then 
        echo "DEBUG_CLI=\"-d\"" >> ${PLIST}; 
    else
        echo ""
        echo "Invalid enable option."
        echo ""
        echo "Enable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 enable [database|client-syslog|agentless|debug]"
        exit 1;
    fi         

    
}



# Enables/disables additional daemons
disable()
{
    if [ "X$2" = "X" ]; then
        echo ""
        echo "Disable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 disable [database|client-syslog|agentless|debug]"
        exit 1;
    fi
    
    if [ "X$2" = "Xdatabase" ]; then
        echo "DB_DAEMON=\"\"" >> ${PLIST};
    elif [ "X$2" = "Xclient-syslog" ]; then
        echo "CSYSLOG_DAEMON=\"\"" >> ${PLIST};
    elif [ "X$2" = "Xagentless" ]; then
        echo "AGENTLESS_DAEMON=\"\"" >> ${PLIST};    
    elif [ "X$2" = "Xdebug" ]; then 
        echo "DEBUG_CLI=\"\"" >> ${PLIST}; 
    else
        echo ""
        echo "Invalid disable option."
        echo ""
        echo "Disable options: database, client-syslog, agentless, debug"
        echo "Usage: $0 disable [database|client-syslog|agentless|debug]"
        exit 1;
    fi         

    
}



# Status function
status()
{
    RETVAL=0
    for i in ${DAEMONS}; do
        pstatus ${i};
        if [ $? = 0 ]; then
            echo "${i} not running..."
            RETVAL=1
        else
            echo "${i} is running..."
        fi
    done
    exit $RETVAL
}

testconfig()
{
    # We first loop to check the config. 
    for i in ${SDAEMONS}; do
        ${DIR}/bin/${i} -t ${DEBUG_CLI};
        if [ $? != 0 ]; then
            echo "${i}: Configuration error. Exiting"
            unlock;
            exit 1;
        fi    
    done
}

# Start function
start()
{
    SDAEMONS="${DB_DAEMON} ${CSYSLOG_DAEMON} ${AGENTLESS_DAEMON} ospatrol-maild ospatrol-execd ospatrol-analysisd ospatrol-logcollector ospatrol-remoted ospatrol-syscheckd ospatrol-monitord"
    
    echo "Starting $NAME $VERSION (by $AUTHOR)..."
    echo | ${DIR}/bin/ospatrol-logtest > /dev/null 2>&1;
    if [ ! $? = 0 ]; then
        echo "ospatrol analysisd: Testing rules failed. Configuration error. Exiting."
        exit 1;
    fi    
    lock;
    checkpid;

    
    # We actually start them now.
    for i in ${SDAEMONS}; do
        pstatus ${i};
        if [ $? = 0 ]; then
            ${DIR}/bin/${i} ${DEBUG_CLI};
            if [ $? != 0 ]; then
		echo "${i} did not start correctly.";
                unlock;
                exit 1;
            fi 

            echo "Started ${i}..."            
        else
            echo "${i} already running..."                
        fi    
    
    done    

    # After we start we give 2 seconds for the daemons
    # to internally create their PID files.
    sleep 2;
    unlock;
    echo "Completed."
}

# Process status
pstatus()
{
    pfile=$1;
    
    # pfile must be set
    if [ "X${pfile}" = "X" ]; then
        return 0;
    fi
        
    ls ${DIR}/var/run/${pfile}*.pid > /dev/null 2>&1
    if [ $? = 0 ]; then
        for j in `cat ${DIR}/var/run/${pfile}*.pid 2>/dev/null`; do
            ps -p $j |grep ospatrol >/dev/null 2>&1
            if [ ! $? = 0 ]; then
                echo "${pfile}: Process $j not used by ospatrol, removing .."
                rm -f ${DIR}/var/run/${pfile}-$j.pid
                continue;
            fi
                
            kill -0 $j > /dev/null 2>&1
            if [ $? = 0 ]; then
                return 1;
            fi    
        done    
    fi
    
    return 0;    
}


# Stop all
stopa()
{
    lock;
    checkpid;
    for i in ${DAEMONS}; do
        pstatus ${i};
        if [ $? = 1 ]; then
            echo "Killing ${i} .. ";
            
            kill `cat ${DIR}/var/run/${i}*.pid`;
        else
            echo "${i} not running .."; 
        fi
        
        rm -f ${DIR}/var/run/${i}*.pid
        
     done    
    
    unlock;
    echo "$NAME $VERSION Stopped"
}


### MAIN HERE ###

case "$1" in
  start)
    testconfig
	start
	;;
  stop) 
	stopa
	;;
  restart)
    testconfig
	stopa
        sleep 1;
	start
	;;
  reload)
        DAEMONS="ospatrol-monitord ospatrol-logcollector ospatrol-remoted ospatrol-syscheckd ospatrol-analysisd ospatrol-maild ${DB_DAEMON} ${CSYSLOG_DAEMON} ${AGENTLESS_DAEMON}"
	stopa
	start
        ;;
  status)
    status
	;;
  help)  
    help
    ;;
  enable)
    enable $1 $2;
    ;;  
  disable)
    disable $1 $2;
    ;;  
  *)
    help
esac
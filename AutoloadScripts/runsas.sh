#!/bin/bash
#
# runsas.sh
#
# syslog      Run AutoLoad.sas
#

# Source level_env
. /opt/sasenv/config/Lev1/level_env.sh

SERVER_CONTEXT=SASApp
APPSERVER_ROOT=$LEVEL_ROOT/$SERVER_CONTEXT
AUTOLOAD_ROOT=/data/AutoloadScripts

FILENAME="$AUTOLOAD_ROOT/AutoLoad.sas"
LOG_FILE="$AUTOLOAD_ROOT/Logs/AutoLoad_#Y.#m.#d_#H.#M.#s.log"
LST_FILE="$AUTOLOAD_ROOT/Logs/AutoLoad.lst"
PID_FILE=$AUTOLOAD_ROOT/autoload.pid
CFG_FILE="$AUTOLOAD_ROOT/AutoLoad.cfg"
MOD_FILE="$AUTOLOAD_ROOT/AutoLoad_usermods.cfg"

# Set config file path
export SASCFGPATH="$APPSERVER_ROOT/sasv9.cfg, $APPSERVER_ROOT/sasv9_usermods.cfg, $CFG_FILE, $MOD_FILE"

# Function to run the autoload.sas program and save the pid
fnRunSAS()
{
cd $APPSERVER_ROOT
$SAS_COMMAND -sysin $FILENAME -log $LOG_FILE -print $LST_FILE -batch -noterminal -logparm "rollover=session" &

    echo $! > $PID_FILE
}

# Ensure process listed in autoload.pid is not running
if [ -f $PID_FILE ]; then
    kill -0 $(< $PID_FILE) > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "autoload still running (pid $(< $PID_FILE))"
        exit 1
    else
        fnRunSAS
    fi
else
	fnRunSAS
fi

exit 0

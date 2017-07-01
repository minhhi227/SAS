#!/bin/bash 
#
# unschedule.sh
#
# syslog      Unschedule AutoLoad.sas
#

RUNSAS_PATH="/data/AutoloadScripts/runsas.sh"

crontab -l|fgrep -i -v $RUNSAS_PATH|crontab


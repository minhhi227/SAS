#!/bin/bash 
#
# schedule.sh
#
# syslog      Schedule AutoLoad.sas
#

RUNSAS_PATH="/data/AutoloadScripts/runsas.sh"
TIME_INTERVAL_MINUTES=15


#call to runsas.sh
cat <(fgrep -i -v $RUNSAS_PATH <(crontab -l)) <(echo "*/$TIME_INTERVAL_MINUTES * * * * $RUNSAS_PATH > /dev/null ") | crontab -


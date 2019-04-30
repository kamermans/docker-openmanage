#!/bin/bash

#start dell services
echo "Starting Dell services, this may take a few minutes..."
srvadmin-services.sh start
srvadmin-services.sh status

#run any passed commands
if [ "$#" -gt 0 ]; then
  #use eval instead of exec so this script remains PID 1
  eval "$@"
fi

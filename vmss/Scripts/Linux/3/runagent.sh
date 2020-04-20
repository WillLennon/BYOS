#!/bin/bash

#delete the script folder
rm -rf "/var/lib/waagent/custom-script"

#pass any input argument to the run script
echo "export AGENT_ALLOW_RUNASROOT=1; bash /agent/run.sh $1" | at now

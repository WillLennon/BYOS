#!/bin/bash

rm -rf "/var/lib/waagent/custom-script"

#pass any input argument to the run script
echo "sudo runuser AzDevOps -c \"/bin/bash /agent/run.sh $1\"" | at now

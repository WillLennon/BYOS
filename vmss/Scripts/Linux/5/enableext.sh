#!/bin/bash
# script to run the RM extension enable step

#pass any input argument to the run script
sudo runuser AzDevOps -c \"/bin/bash /agent/run.sh $1\"

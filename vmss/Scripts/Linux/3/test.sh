#!/bin/bash

# We require 3 inputs: $1 is url, $2 is pool, $3 is PAT
# 4th input is option $4 is either '--once' or null
url=$1
pool=$2
pat=$3
runArgs=$4

echo $runArgs

# schedule the build agent to run immediately
/bin/bash ./runagent.sh $runArgs

echo done

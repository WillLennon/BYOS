#!/bin/bash

# We require 3 inputs: $1 is url, $2 is pool, $3 is PAT
url=$1
pool=$2
pat=$3

# configure the build agent
# must set this variable so the build agent scripts don't complain that we're running as root
export AGENT_ALLOW_RUNASROOT=1
echo configuring build agent
./config.sh --unattended --url $url --pool $pool --auth pat --token $pat --acceptTeeEula

# run the agent in its own shell so we do not block this extension
echo running build agent
bash /agent/run.sh

echo done

#!/bin/bash

# We require 3 inputs: $1 is url, $2 is pool, $3 is PAT
url=$1
pool=$2
pat=$3

# Create agent folder
echo creating agent folder
mkdir -p -v /agent

# Copy run script
cp linux_run_agent.sh /agent/linux_run_agent.sh

zipfile=$(find vsts-agent*.tar.gz)
echo unzipping $zipfile into /agent folder
tar -xvf  $zipfile -C /agent
cd /agent

echo installing dependencies
./bin/installdependencies.sh

# install at to be used when we schedule the build agent to run later
apt install at

# configure the build agent
# must set this variable so the build agent scripts don't complain that we're running as root
export AGENT_ALLOW_RUNASROOT=1
echo configuring build agent

$pool="$pool"
echo $pool
./config.sh --unattended --url $url --pool $pool --auth pat --token $pat --acceptTeeEula

# configure crontab to restart the build agent after reboots
# echo enabling crontab to restart the build agent after reboot
# printf "echo rebooted;export AGENT_ALLOW_RUNASROOT=1; bash /agent/run.sh \n" > startup.sh
# printf "@reboot bash /agent/startup.sh \n" > temp.txt
# crontab temp.txt
# rm temp.txt
# crontab -l

# schedule the build agent to run immediately
./linux_run_agent.sh

echo done

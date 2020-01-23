
#!/bin/bash

# We require 3 inputs: $1 is url, $2 is pool, $3 is PAT
url=$1
pool=$2
pat=$3

# Create agent folder
echo creating agent folder
mkdir -p -v /agent

zipfile=$(find vsts-agent*.tar.gz)
echo unzipping $zipfile into /agent folder
tar -xvf  $zipfile -C /agent
cd /agent

echo installing dependencies
./bin/installdependencies.sh

# configure the build agent
# must set this variable so the build agent scripts don't complain that we're running as root
export AGENT_ALLOW_RUNASROOT=1
echo configuring build agent
./config.sh --unattended --url $url --pool '$pool' --auth pat --token $pat --acceptTeeEula

# configure crontab to restart the build agent after reboots
# echo enabling crontab to restart the build agent after reboot
# printf "echo rebooted;export AGENT_ALLOW_RUNASROOT=1; bash /agent/run.sh \n" > startup.sh
# printf "@reboot bash /agent/startup.sh \n" > temp.txt
# crontab temp.txt
# rm temp.txt
# crontab -l

# run the agent in its own shell so we do not block this extension
echo running build agent
bash /agent/run.sh

echo done

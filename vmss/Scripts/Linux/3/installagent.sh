#!/bin/bash

# We require 3 inputs: $1 is url, $2 is pool, $3 is PAT
# 4th input is option $4 is either '--once' or null
url=$1
pool=$2
pat=$3
runArgs=$4

echo url $url
echo pool $pool
echo pat $pat

# Create our user account
echo creating AzDevOps account
sudo useradd -m AzDevOps
sudo usermod -a -G sudo AzDevOps

# Create agent folder
echo creating agent folder
mkdir -p -v /agent

# Copy run script
cp runagent.sh /agent/runagent.sh

zipfile=$(find vsts-agent*.tar.gz)
echo unzipping $zipfile into /agent folder
tar -xvf  $zipfile -C /agent
cd /agent

echo installing dependencies
./bin/installdependencies.sh

# install at to be used when we schedule the build agent to run later
apt install at

echo url $url
echo pool $pool
echo pat $pat

# configure the build agent
# calling bash here so the quotation marks around $pool get respected
echo configuring build agent
sudo runuser AzDevOps -c '/bin/bash ./config.sh --unattended --url $url --pool "$pool" --auth pat --token $pat --acceptTeeEula --replace'

# schedule the build agent to run immediately
/bin/bash ./runagent.sh $runArgs

echo done

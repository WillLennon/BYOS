#!/bin/bash

# Create agent folder
echo creating agent folder
mkdir -p -v /agent

zipfile=$(find vsts-agent*.tar.gz)
echo unzipping $zipfile into /agent folder
tar -xvf  $zipfile -C /agent
cd /agent

echo installing dependencies
./bin/installdependencies.sh

echo not configuring or installing build agent.

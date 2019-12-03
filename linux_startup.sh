# We require 3 inputs: $1 is url, $2 is poolName, $3 is PAT
url=$1
pool=$2
pat=$3

zipfile=$(find vsts-agent*.tar.gz)
echo the zip file is $zipfile

# requires root
echo creating agent folder
mkdir -p -v /agent

echo unzipping agent
tar -xvf  $zipfile -C /agent
cd /agent

echo installing dependencies
./bin/installdependencies.sh

# must set this variable so the script won't complain that we're running as root
export AGENT_ALLOW_RUNASROOT=1

echo removing build agent
./config.sh remove

echo configuring build agent
./config.sh --unattended --url $url --pool $pool --auth pat --token $pat --acceptTeeEula

echo running build agent
sh ./run.sh

echo done

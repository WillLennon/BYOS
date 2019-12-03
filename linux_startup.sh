# We require 3 inputs: $1 is url, $2 is poolName, $3 is PAT
url=$1
pool=$2
pat=$3

echo url is $url
echo pool is $pool
echo pat is $pat

pwd

zipfile=$(find vsts-agent*.tar.gz)
echo the zip file is $zipfile

# requires root
echo creating agent folder
mkdir -p -v /agent

echo unzipping agent
tar -xvf  $zipfile -C /agent
cd /agent
pwd

echo installing dependencies
./bin/installdependencies.sh

echo configuring build agent. AGENT_ALLOW_RUNASROOT=1
# must set this variable so the script won't fail
export AGENT_ALLOW_RUNASROOT=1
./config.sh --unattended --acceptTeeEula --url $url --pool $pool --auth pat --token $pat

pwd
ls -a

#echo running build agent
#sh ./run.sh

echo done

# We require 3 inputs: $1 is url, $2 is poolName, $3 is PAT
url=$1
poolName=$2
pat=$3

echo url is $url
echo pool name is $poolName
echo pat is $pat

pwd

zipfile=$(find vsts-agent*.tar.gz)
echo the zip file is $zipfile

# requires root
echo creating agent folder
mkdir -p -v /agent

echo unzipping agent
#tar -zxvf  $zipfile --directory /agent
#cd /agent
#ls ./bin/

# requires sudo
#./bin/installdependencies.sh

# requires NO sudo
#./config.sh --unattended --acceptTeeEula --url $url --pool $poolName --auth pat --token $pat
#./run.sh


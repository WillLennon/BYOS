echo $1
echo $2
echo $3

# We require 3 inputs: $1 is url, $2 is poolName, $3 is PAT
url=$1
poolName=$2
pat=$3

echo url is $url
echo pool name is $poolName
echo pat is $pat

pwd
ls

mkdir -p /agent

zipfile=$(find vsts-agent*.tar.gz)

echo the zip file is $zipfile

tar -zxvf  $zipfile --directory /agent
cd /agent
ls ./bin/
./bin/installdependencies.sh
./config.sh --unattended --acceptTeeEula --url $url --pool $poolName --auth pat --token $pat
./run.sh


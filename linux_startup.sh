echo $1
echo $2
echo $3

# We require 3 inputs: $1 is url, $2 is poolName, $3 is PAT
url = $1
poolName = $2
pat = $3

echo $url
echo $poolName
echo $pat

ls

mkdir -p /agent;
tar zxvf  ~/vsts-agent-linux-x64-2.160.1.tar.gz --directory /agent;
cd /agent;
ls ./bin/
./bin/installdependencies.sh;
./config.sh --unattended --acceptTeeEula --url $url --pool $poolName --auth pat --token $pat && ./run.sh


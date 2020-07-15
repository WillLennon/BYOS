#!/bin/bash
# script for the RM extension install step

# We require 3 inputs: $1 is url, $2 is pool, $3 is PAT
# 4th input is option $4 is either '--once' or null
url=$1
pool=$2
token=$3
runArgs=$4

echo "url is " $url
echo "pool is " $pool
echo "runArgs is " $runArgs

# get the folder where the script is executing
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "directory is " $dir

# Create our user account
echo creating AzDevOps account
sudo useradd -m AzDevOps
sudo usermod -a -G docker AzDevOps
sudo usermod -a -G adm AzDevOps
sudo usermod -a -G sudo AzDevOps

echo "Giving AzDevOps user access to the '/home', '/usr/share', and '/opt' directories."
sudo chmod -R +r /home
setfacl -Rdm "u:AzDevOps:rwX" /home
setfacl -Rb /home/AzDevOps
#sudo chmod -R 777 /usr/share
#setfacl -Rdm "u:AzDevOps:rwX" /usr/share
#sudo chmod -R 777 /opt
#setfacl -Rdm "u:AzDevOps:rwX" /opt
echo 'AzDevOps ALL=NOPASSWD: ALL' >> /etc/sudoers

# unzip the agent files
zipfile=$(find $dir/vsts-agent*.tar.gz)
echo "zipfile is " $zipfile

if !(test -f "$dir/bin/Agent.Listener"); then
    echo "Unzipping agent"
    tar -xvf  $zipfile -C $dir
fi

rm $zipfile
cd $dir

# grant broad permissions in the agent folder
sudo chmod -R 777 $dir
sudo chown -R AzDevOps:AzDevOps $dir

# install dependencies
echo installing dependencies
./bin/installdependencies.sh

# Run any user warmup script if it exists.
# This must be done before we configure the agent because once the agent registers with Azure DevOps
# We are only given 5 minutes between registering and starting the agent before Azure DevOps tears down the VM.
warmup='/warmup.sh'
if test -f "$warmup"; then
    echo "Executing $warmup"
    chmod +x $warmup
    sudo runuser AzDevOps -c "/bin/bash $warmup"
fi

apt install at

# configure the build agent
# calling bash here so the quotation marks around $pool get respected
echo configuring build agent
sudo runuser AzDevOps -c "/bin/bash $dir/config.sh --unattended --url $url --pool \"$pool\" --auth pat --token $token --acceptTeeEula --replace"

# install at to be used when we schedule the build agent to run and not wait for it to finish
echo "sudo runuser AzDevOps -c \"/bin/bash $dir/run.sh $runArgs\"" | at now

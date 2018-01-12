#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "This script is going to install the node miner in the /root folder"

# ASK FOR DOMAIN NAME
echo Please insert domain pointed to this server
read DOMAIN
echo Please insert number of threads dedicated for miner
read THREAD
echo Please insert your wallet seed for miner
read SEED
 
# Determine OS platform
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
# If Linux, try to determine specific distribution
if [ "$UNAME" == "linux" ]; then
    # If available, use LSB to identify distribution
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        export DISTRO=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    # Otherwise, use release info file
    else
        export DISTRO=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi

if [[ $DISTRO == *"ubuntu"* ]] || [[ $DISTRO == *"Ubuntu"* ]]; then
    # INSTALLATION COMMANDS
    apt-get -y update
    apt-get -y install curl
    apt-get -y update
    apt-get -y install screen
    apt-get -y update
    apt-get -y install certbot
    curl -sL https://deb.nodesource.com/setup_9.x -o nodesource_setup.sh
    bash nodesource_setup.sh
    apt-get -y install nodejs build-essential git
    cd ~
    git clone https://github.com/nimiq-network/core
    cd core
    wget http://nimiq-repo.layerwall.it/public_repo/node_modules.tar
    tar -xvf node_modules.tar
    rm -rf node_modules.tar
    git checkout release
    sudo npm install
    sudo npm run build
    cd clients/nodejs && npm install
    cd ..
    cd ..
    npm run prepare
    # CREATE LAUNCH FILE
    cd ~
    touch start-miner.sh
    echo "cd ~/core/clients/nodejs/" > start-miner.sh
    echo "UV_THREADPOOL_SIZE=$THREAD screen -dmS NIMIQ-MINER node index.js --host $DOMAIN --port 8080 --miner=$THREAD --wallet-seed=$SEED" >> start-miner.sh
    chmod 755 start-miner.sh
     
     
    # LAUNCH MINER
    ./start-miner.sh
fi
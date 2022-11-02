#!/usr/bin/env bash
set -e

currentShell=$SHELL
shellSource=""

if [ $currentShell == "/bin/zsh" ] ; then 
    shellSource="~/.zshrc"
elif [ $currentShell == "/bin/bash" ] ; then 
    shellSource="~/.bashrc"
fi

currentUser="$(id -u)"
if [ $currentUser -eq 0 ] ; then    
    echo "Please dont start the execution as Root user. Exiting...." ; 
    exit 1
fi

curl -o /tmp/minikube_latest_amd64.deb -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb 
sudo dpkg -i /tmp/minikube_latest_amd64.deb

if ! which minikube > /dev/null ; then
  echo "Minikube not installed properly please check"
  exit 2
fi

minikube start
minikube kubectl -- get po -A

if [ -z $shellSource ]; then 
  echo "ZSH, Bash support is available for now. Please add kubectl alias manually."
  exit 3
fi

echo 'alias kubectl="minikube kubectl --"' >> $currentUser
exec $SHELL
kubectl get pods
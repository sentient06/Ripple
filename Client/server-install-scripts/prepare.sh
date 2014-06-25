#!/usr/bin/env bash
# -------------------------------------------------------------------------------
cya="\033[0;36m"
ncl="\033[0m" #No colour
mainUser=`whoami`
printf "\n\n${cya}Installing GIT${ncl}\n\n"
sudo -S apt-get install --yes curl git-core
printf "\n\n${cya}Server will restart in 5 seconds${ncl}\n\n"
printf "\n\n${cya}Installing RVM${ncl}\n\n"
\curl -L https://get.rvm.io | sudo bash -s stable
sudo adduser $mainUser rvm
printf "\n\n${red}Server will restart in 5 seconds${ncl}\n\n"
sleep 5
sudo reboot
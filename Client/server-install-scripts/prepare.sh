#!/usr/bin/env bash
# -------------------------------------------------------------------------------
red="\033[0;31m"
cya="\033[0;36m"
ncl="\033[0m" #No colour
mainUser=`whoami`
printf "\n\n${cya}Installing GIT${ncl}\n\n"
sudo -S apt-get install --yes curl git-core
printf "\n\n${cya}Installing RVM${ncl}\n\n"
\curl -L https://get.rvm.io | sudo bash -s stable
sudo adduser $mainUser rvm
echo progress-bar >> /home/$mainUser/.curlrc
printf "\n\n${red}Server will restart in 5 seconds${ncl}\n\n"
sleep 5
sudo reboot
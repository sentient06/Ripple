#! /bin/bash
source /etc/profile.d/rvm.sh
sudo -u deploy /usr/local/rvm/bin/ruby /home/deploy/scripts/trigger.rb $@
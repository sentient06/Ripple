#! /bin/bash
# source /etc/profile.d/rvm.sh
sudo -u deploy -E ruby /home/deploy/scripts/trigger.rb $@
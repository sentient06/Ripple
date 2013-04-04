#! /bin/bash
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"
sudo -u deploy /usr/local/rvm/bin/ruby /home/deploy/scripts/trigger.rb $@
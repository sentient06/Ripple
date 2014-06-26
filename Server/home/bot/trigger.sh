#!/usr/bin/env bash
PATH=$PATH:/usr/local/rvm/bin # Add RVM to PATH for scripting
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm" # Load RVM function
sudo -u deploy -E ruby /home/deploy/scripts/trigger.rb $@
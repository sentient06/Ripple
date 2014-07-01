#!/usr/bin/env bash
# -------------------------------------------------------------------------------

red="\033[0;31m"
gre="\033[0;32m"
yel="\033[0;33m"
blu="\033[0;34m"
pur="\033[0;35m"
cya="\033[0;36m"
ncl="\033[0m" #No colour

mainUser=`whoami`
PATH=$PATH:/usr/local/rvm/bin # Add RVM to PATH for scripting
[[ -s "/usr/local/rvm/scripts/rvm" ]] && . "/usr/local/rvm/scripts/rvm" # Load RVM function
printf "\n\n${cya}Installing RVM Requirements${ncl}\n\n"
sleep 3
rvm requirements
printf "\n\n${cya}Installing Ruby${ncl}\n\n"
sleep 3
rvm install ruby-head
rvm use ruby-head
rubyVersion=`rvm list | awk '/ruby-head/{print x;print};{x=$0}' | sed -n '/ruby-head/{g;1!p;};h' | awk -F ' ' '{print $1}'`
originalRubyGems="${rubyVersion}@ripple"
printf "\n\n${cya}Creating Gemset${ncl}\n\n"
sleep 3
rvm use $originalRubyGems --create --default
printf "\n\n${cya}Installing Rails${ncl}\n\n"
sleep 3
gem install --no-rdoc --no-ri rails
sleep 10
printf "\n\n${cya}Renaming Gemset${ncl}\n\n"
sleep 3
railsVersion=`rails -v | awk '/Rails/{print $2}'`
originalRubyGems="${rubyVersion}@ripple"
finalGemset="${rubyVersion}@${railsVersion}"
rvm gemset rename $originalRubyGems $finalGemset
rvm gemset use $finalGemset --default
printf "\n\n${cya}Installing Thin${ncl}\n\n"
sleep 3
gem install --no-rdoc --no-ri thin
rvmsudo thin install
sudo /usr/sbin/update-rc.d -f thin defaults
printf "\n\n${cya}Installing PostgresSQL${ncl}\n\n"
sleep 3
sudo apt-get install --yes postgresql libpq-dev
printf "\n\n${cya}Changing PostgresSQL root's password${ncl}\n\n"
echo -n "New password: "
stty -echo
read postgreSqlPass
stty echo
echo "" # force a carriage return to be output
echo "ALTER USER postgres WITH ENCRYPTED PASSWORD '${postgreSqlPass}';" | sudo -u postgres psql;
# Replaces all "peer" for "md5":
sudo sed -ie 's/\(^local *all *[a-z]* *\)peer/\1md5/' /etc/postgresql/9.1/main/pg_hba.conf
sudo service postgresql restart
printf "\n\n${cya}Installing Nginx${ncl}\n\n"
sleep 3
sudo apt-get install --yes nginx
printf "\n\n${cya}Adding users${ncl}\n\n"
sleep 3
printf "${pur}User bot will trigger all Ripple actions.${ncl}\n"
echo -n "New password for bot: "
stty -echo
read botPassword
stty echo
echo "" # force a carriage return to be output
printf "${pur}User deploy will execute all Rails actions for deployment.${ncl}\n"
echo -n "New password for deploy: "
stty -echo
read deployPassword
stty echo
echo "" # force a carriage return to be output
printf "${pur}User git will execute all Git actions.${ncl}\n"
echo -n "New password for git: "
stty -echo
read gitPassword
stty echo
echo "" # force a carriage return to be output
sudo adduser deploy --group --add_extra_groups rvm
sudo adduser bot --gecos ",,," --disabled-password
sudo adduser deploy --gecos ",,," --disabled-password
sudo adduser git --gecos ",,," --disabled-password
echo "bot:${botPassword}" | sudo chpasswd
echo "deploy:${deployPassword}" | sudo chpasswd
echo "git:${gitPassword}" | sudo chpasswd
sudo gpasswd --members bot,deploy,git rvm
sudo gpasswd --members bot,git deploy
# sudo sh -c "echo \"bot      ALL=(git)      NOPASSWD: ALL\ndeploy   ALL=(git)      NOPASSWD: ALL\ndeploy   ALL=(postgres) NOPASSWD: ALL\n%deploy  ALL=(deploy)   NOPASSWD: ALL\n\ndeploy   ALL=(ALL) NOPASSWD: /usr/sbin/service nginx start, /usr/sbin/service nginx stop\ndeploy   ALL=(ALL) NOPASSWD: /usr/sbin/service thin start, /usr/sbin/service thin stop\" >> /etc/sudoers"
visudoFile="
    bot      ALL=(git)      NOPASSWD: ALL
    git      ALL=(bot)      NOPASSWD: /bin/rm, /bin/ln
    deploy   ALL=(git)      NOPASSWD: ALL
    deploy   ALL=(postgres) NOPASSWD: ALL
    %deploy  ALL=(deploy)   NOPASSWD: ALL
    deploy   ALL=(ALL) NOPASSWD: /usr/sbin/service nginx start, /usr/sbin/service nginx stop
    deploy   ALL=(ALL) NOPASSWD: /usr/sbin/service thin start, /usr/sbin/service thin stop
"
sudo sh -c "echo \"${visudoFile}\" >> /etc/sudoers"
sudo sh -c "echo \"\n# Disable root login\nPermitRootLogin no\n\n#Allow the following users\nAllowUsers ${mainUser} git bot deploy\" >> /etc/ssh/sshd_config"
sudo service ssh restart
sudo mkdir /home/git/.ssh
sudo mkdir /home/bot/.ssh
sudo cp /home/$mainUser/.ssh/authorized_keys /home/git/.ssh/authorized_keys
sudo cp /home/$mainUser/.ssh/authorized_keys /home/bot/.ssh/authorized_keys
sudo chown -R git:git /home/git/.ssh
sudo chown -R bot:bot /home/bot/.ssh
printf "\n\n${cya}Changing directory permissions${ncl}\n\n"
sleep 3
sudo mkdir /var/www
sudo chown deploy:deploy /var/www
sudo chown deploy:deploy /etc/nginx/sites-available
sudo chown deploy:deploy /etc/nginx/sites-enabled
sudo chown deploy:deploy /etc/thin
printf "\n${cya}Installing Ripple${ncl}\n\n"
sleep 3
sudo mkdir -p /ripple/master
sudo mkdir -p /ripple/ripple.git
sudo mkdir /home/git/repositories
sudo mkdir /home/deploy/data
sudo chown -R git:git /ripple
sudo chown git:git /home/git/repositories
sudo chown deploy:deploy /ripple/master
sudo chown deploy:deploy /home/deploy/data
sudo chmod 775 /ripple/master
cd /ripple/ripple.git
sudo -u git git init --bare
sudo rm -f /ripple/ripple.git/hooks/post-update
sudo mv $HOME/post-update /ripple/ripple.git/hooks/post-update
sudo chown git:git /ripple/ripple.git/hooks/post-update
sudo chmod 755 /ripple/ripple.git/hooks/post-update
sudo -u deploy git clone /ripple/ripple.git /ripple/master
printf "\n${cya}Done${ncl}\n\n"
printf "${red}Server will restart in 5 seconds${ncl}\n\n"
sleep 5
sudo reboot
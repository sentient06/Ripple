#Ruby Deployment for Humans

These files are intended to be used in a ruby on rails in production environment and make the deployment as easy to use as a 'git-push'.

The workflow is inspired by Heroku.

Please refer to the wiki on Github for details.

##To update server using git (testing solution):

First, use admin to execute `sudo visudo`:

###VISUDO file:

    bot      ALL=(git)      NOPASSWD: ALL
    git      ALL=(bot)      NOPASSWD: /bin/rm /home/bot/trigger.sh, /bin/ln
    deploy   ALL=(git)      NOPASSWD: ALL
    deploy   ALL=(postgres) NOPASSWD: ALL
    %deploy  ALL=(deploy)   NOPASSWD: ALL
    deploy   ALL=(ALL) NOPASSWD: /usr/sbin/service nginx start, /usr/sbin/service nginx stop
    deploy   ALL=(ALL) NOPASSWD: /usr/sbin/service thin start, /usr/sbin/service thin stop

###Git repository:

Then do the following to allocate the repository:

    cd /
    sudo mkdir rdh
    sudo chown git:git /rdh/
    cd rdh
    sudo mkdir master
    sudo chown deploy:deploy master
    sudo chmod 775 master/
    sudo -u git mkdir RDH.git && cd RDH.git
    sudo -u git git init --bare
    cd hooks
    sudo -u git vim post-update

**Paste the following:**

    #!/bin/sh

    red='\033[0;31m';
    gre='\033[0;32m';
    yel='\033[0;33m';
    ncl='\033[0m'; #No colour

    echo "${gre}Post receive hook: Updating RDH!${yel}"

    export GIT_WORK_TREE=/rdh/master
    cd $GIT_WORK_TREE
    sudo -u deploy git pull
    sudo -u deploy git checkout master -f

    echo "${gre}Deploy: Re-linking scripts directory.${ncl}"
    sudo -u deploy rm /home/deploy/scripts
    sudo -u deploy ln -s /rdh/master/Server/home/deploy/scripts /home/deploy/scripts
    echo "${gre}Scripts relinked.${ncl}";

    echo "${gre}Deploy: Re-linking templates directory.${ncl}"
    sudo -u deploy rm /home/deploy/templates
    sudo -u deploy ln -s /rdh/master/Server/home/deploy/templates /home/deploy/templates
    echo "${gre}Templates relinked.${ncl}";

    echo "${gre}Git: Re-linking scripts directory.${ncl}"
    rm /home/git/scripts
    ln -s /rdh/master/Server/home/git/scripts /home/git/scripts
    echo "${gre}Scripts relinked.${ncl}";

    echo "${gre}Git: Re-linking templates directory.${ncl}"
    rm /home/git/templates
    ln -s /rdh/master/Server/home/git/templates /home/git/templates
    echo "${gre}Templates relinked.${ncl}";

    echo "${gre}Bot: Re-linking trigger.${ncl}"
    sudo -u bot rm /home/bot/trigger.sh
    sudo -u bot ln -s /rdh/master/Server/home/bot/trigger.sh /home/bot/trigger.sh
    echo "${gre}Trigger relinked.${ncl}";

    echo "${gre}Done!${ncl}"

**Save (:wq) and continue:**

    sudo -u git chmod +x ./post-update
    sudo -u deploy git clone /rdh/RDH.git /rdh/master
    exit

##Client computer

###Git repository

Now, use git in your client computer to clone RDH and add your server as a remote host, something like:

    git clone git@github.com:sentient06/RDH.git
    git add remote myserver git@myserver:/rdh/RDH.git
    git push myserver master

###Client application & RSA key

To make the mac client usefull, I would recomend adding a symbolic link to your `/usr/local/bin/` directory.

Also, add your RSA key to the user bot in your server:

    ln -s /Users/<path-to-RDH>/RDH/Client/a.out /usr/local/bin/rdh
    scp ~/.ssh/id_rsa.pub bot@myserver:~
    ssh bot@myserver
    cat ~/id_rsa.pub >> ~/.ssh/authorized_keys
    rm ~/id_rsa.pub
    exit

###Try it!

Now you can execute all RDH actions using your `rdh` command and if you want to make any changes, you can commit to your server.

    rdh server myserver
    rdh test
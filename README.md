#Ripple - Ruby Deployment for Humans

These files are intended to be used in a ruby on rails in production environment and make the deployment as easy to use as a 'git-push'.

The workflow is inspired by Heroku.

Please refer to the wiki on Github for details.

##To setup server using git (prototype):

This method was tested only on Ubuntu 12 Server.
The server should have nothing more than SSH access and a pair of RSA keys.
The user must be able to use "sudo" and log in through SSH.

First, copy all files from "server-install-scrips" to your main user's home directory:

    scp prepare.sh install.sh post-update ripple-read-me.txt <user>@<server>:~

Second, execute the prepare script:

    ssh -t <user>@<server> "bash prepare.sh"

The server will restart. After a while, execute the install script:

    ssh -t <user>@<server> "bash install.sh"

The server must restart one more time. After that, all will be ready for Ripple. In the client side, you must add your own server to Ripple and push it.

    git add remote myServer git@<server>:/ripple/ripple.git
    git push myServer master

###Client application & RSA key

To make the mac client usefull, I would recomend adding a symbolic link to your `/usr/local/bin/` directory.

This can be achieved by browsing to the Ripple/Client/Ripple/Ripple/ directory and executing:

    ln -s `pwd`/ripple /usr/local/bin/rp

###Try it!

Now you can execute all RDH actions using your `rdh` command and if you want to make any changes, you can commit to your server.

    rp server myserver
    rp test

## What does these things do?

The first installation script installs GIT and RVM (multi-user). It then adds your normal user to the RVM group and restarts the server.

The second script installs the last stable Ruby version, then Rails, then it renames the gemset to match Rails version. Then it installs Thin server and PostgresSQL.

It prompts the user for a root password for PostgresSQL, then it changes the "peer" entries for "md5" in the PostgresSQL config file. Then it installs Nginx and prompts for passwords for the creation of 3 users called: 'bot', 'git' and 'deploy'.

Then it creates the users with home directories, password and all, adds them to RVM group, 'deploy' group and 'git' group (as necessary), then it adds entries in the visudo file to avoid password prompting in the Ripple actions.

Then it blocks SSH access for root and allows for 'bot' and 'git' and your own user. It makes a copy of your authorised RSA keys to 'bot' and 'git', it changes the ownership of the Nginx and Thin configuration directories to 'deploy'.

Finally, it creates a directory for your applications in '/var/www/' and a GIT and repository directories for Ripple. It makes a copy of a post-update hook used to setup Ripple and resets the server. =)

##Warning

This project is purely experimental. Please read all documentation and codes before using it with sensitive information.

Have fun!
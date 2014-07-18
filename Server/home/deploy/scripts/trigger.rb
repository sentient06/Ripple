#! /bin/ruby

require '/home/deploy/scripts/deployment_actions.rb'
deployer = DeploymentActions.new

#-------------------------------------------------------------------------------
# rp test # Tests <server>
if ARGV[0] == 'test'
    deployer.test
end
# rp list # Lists apps from <server>
if ARGV[0] == 'list'
    deployer.list
end
# ---------------------------------------
# rp server # Displays server name
# rp server list # Lists servers
# rp server add <server> # Adds a new server <server>
# rp server remove <server> # Removes a server <server>
# rp server use <server> # Assigns a server <server>
# ---------------------------------------
# rp add --app <app> --url <url> --ports <ports> # Adds an <app> to <server> using url <url> and <ports> ports
if ARGV[0] == 'add'
    deployer.addApplication ARGV[1], ARGV[2], ARGV[3]
end
# ---------------------------------------
# rp app <app> <command> # Executes <command> for <app>
# rp app <app> status # Check status of app <app>
if ARGV[0] == 'status'
    deployer.appStatus ARGV[1]
end
# rp app <app> destroy # Destroys <app>
if ARGV[0] == 'destroy'
    argv0 = ARGV.shift
    argv1 = ARGV.shift
    print "\n\033[0;31mAre you sure you want to destroy this application? \033[0;36m[yes|no]\033[0m: "
    confirmation = gets.chomp
    if confirmation == "yes"
        print "\n\033[0;31mPlease type the name of the application to confirm\033[0m: "
        name = gets.chomp
        print "\n"
        if argv1 == name
            deployer.destroy(argv1)
        end
    end
end
# rp app <app> stop # Stops <app> from running
if ARGV[0] == 'stop'
    deployer.stopApplication ARGV[1]
end
# rp app <app> disable # Disables from Nginx
if ARGV[0] == 'disable'
    deployer.disable ARGV[1]
end
# rp app <app> hinder # Deletes Nginx config file for <app>
if ARGV[0] == 'hinder'
    deployer.hinder ARGV[1]
end
# rp app <app> restart # Restarts <app>
if ARGV[0] == 'restart'
    deployer.restart ARGV[1]
end
# rp app <app> avail # Saves Nginx config file for <app>
if ARGV[0] == 'avail'
    deployer.avail ARGV[1]
end
# rp app <app> enable # Enables in Nginx
if ARGV[0] == 'enable'
    deployer.enable ARGV[1]
end
# rp app <app> start # Starts <app>
if ARGV[0] == 'start'
    deployer.startApplication ARGV[1]
end
# rp app <app> deploy # Deploys <app>
if ARGV[0] == 'deploy'
    deployer.deploy ARGV[1]
end

# rp app <app> set <option> <value> # Sets an <option> of an <app> to value <value>
if ARGV[0] == 'set'
    deployer.set ARGV[1], ARGV[2]
end
# ---------------------------------------
# rp delete -a <app> # Removes an <app> from <server>
# ---------------------------------------
# rp nginx <command> # Executes <command> for nginx
if ARGV[0] == 'nginx'
    if ARGV[1] == 'stop'
        deployer.stopNginx
    elsif ARGV[1] == 'start'
        deployer.startNginx
    end
end
# rp thin <command> # Executes <command> for thin
# ---------------------------------------
if ARGV[0] == 'update'
    deployer.updateConfigs
end
# rp all <command>
if ARGV[0] == 'allApplications'
    if ARGV[1] == 'stop'
        # rp all stop
        deployer.stopAll
    elsif ARGV[1] == 'start'
        # rp all start
        deployer.startAll
    elsif ARGV[1] == 'restart'
        # rp all restart
        deployer.restartAll
    elsif ARGV[1] == 'update'
        # rp all update
        deployer.updateConfigs
    end
end

# rp app <app> [db|database] backup (local)
# rp app <app> [db|database] backup copy ./test
# rp app <app> [db|database] backup delete (local)
# rp app <app> [db|database] backup restore (local)
# rp app <app> [db|database] backup restore ./test

if ARGV[0] == 'databaseBackup'
    deployer.databaseBackup ARGV[1]
end
if ARGV[0] == 'databaseDelete'
    deployer.databaseDelete ARGV[1]
end
if ARGV[0] == 'databaseRestore'
    deployer.databaseRestore ARGV[1]
end

# This is to update server-side information based on new code.
if ARGV[0] == 'master-update'
    deployer.masterUpdate
end

# This is to show the hashes.
if ARGV[0] == 'master-debug'
    deployer.masterDebug
end

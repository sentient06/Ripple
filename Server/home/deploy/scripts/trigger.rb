#! /bin/ruby

require '/home/deploy/scripts/deployment_actions.rb'
deployer = DeploymentActions.new

# Old code:
# #-------------------------------------------------------------------------------
# # General actions

# if ARGV[0] == 'test'
#     deployer.test
# end

# #-------------------------------------------------------------------------------
# # Application actions

# if ARGV[0] == 'status'
#     deployer.appStatus ARGV[1]
# end

# if ARGV[0] == 'set'
#     deployer.setParameters ARGV[1], ARGV[2]
# end

# #-------------------------------------------------------------------------------
# # Nginx symbolic link:

# if ARGV[0] == 'enable'
#     deployer.enableNginxConfigFile(ARGV[1])
# end

# if ARGV[0] == 'disable'
#     deployer.disableNginxConfigFile(ARGV[1])
# end

# # Nginx real config files:

# if ARGV[0] == 'avail'
#     deployer.availNginxConfigFile(ARGV[1])
# end

# if ARGV[0] == 'hinder'
#     deployer.deleteNginxConfigFile(ARGV[1])
# end

# # Starts and stops Nginx and Thin accordinly:

# if ARGV[0] == 'start'
#     deployer.startApp(ARGV[1])
# end

# if ARGV[0] == 'stop'
#     deployer.stopApp(ARGV[1])
# end

# #-------------------------------------------------------------------------------
# # Testing

# if ARGV[0] == 'eval'
#     eval(ARGV[1])
# end

# #-------------------------------------------------------------------------------
# # Old (check)

# if ARGV[0] == 'destroy'
#     deployer.destroy ARGV[1]
# end

# if ARGV[0] == 'deploy'
#     deployer.deploy(ARGV[1])
# end

# if ARGV[0] == 'resethard'
#     deployer.resethard
# end

# if ARGV[0] == 'restart'
#     deployer.restart ARGV[1]
# end






# NEW
#-------------------------------------------------------------------------------
# rp test # Tests <server>
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
# rp app <app> set <option> <value> # Sets an <option> of an <app> to value <value>
# rp app <app> stop # Stops <app> from running
# rp app <app> disable # Disables from Nginx
# rp app <app> enable # Enables in Nginx
# rp app <app> restart # Restarts <app>
# rp app <app> start # Starts <app>
# rp app <app> avail # Saves Nginx config file for <app>
# rp app <app> hinder # Deletes Nginx config file for <app>
# rp app <app> deploy # Deploys <app>
if ARGV[0] == 'deploy'
    deployer.deploy ARGV[1]
end
# ---------------------------------------
# rp delete -a <app> # Removes an <app> from <server>
# ---------------------------------------
# rp nginx <command> # Executes <command> for nginx
# rp thin <command> # Executes <command> for thin
# ---------------------------------------
# rp all <command>
# rp all update
if ARGV[0] == 'update'
    deployer.deploy ARGV[1]
end
# rp all stop
# rp all restart
# rp all 
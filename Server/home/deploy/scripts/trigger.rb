#! /bin/ruby

require '/home/deploy/scripts/deployment_actions.rb'
deployer = DeploymentActions.new

#-------------------------------------------------------------------------------
# Working

if ARGV[0] == 'test'
    deployer.test
end

if ARGV[0] == 'list'
    deployer.list
end

if ARGV[0] == 'status'
    deployer.appStatus ARGV[1]
end

if ARGV[0] == 'create'
    deployer.create ARGV[1], ARGV[2], ARGV[3]
end

if ARGV[0] == 'set'
    deployer.setParameters ARGV[1], ARGV[2]
end

#-------------------------------------------------------------------------------
# Testing

# Nginx symbolic link:

if ARGV[0] == 'enable'
    puts "ok"
    deployer.enableNginxConfigFile(ARGV[1])
end

if ARGV[0] == 'disable'
    deployer.disableNginxConfigFile(ARGV[1])
end

# Nginx real config files:

if ARGV[0] == 'avail'
    deployer.availNginxConfigFile(ARGV[1])
end

if ARGV[0] == 'hinder'
    deployer.deleteNginxConfigFile(ARGV[1])
end

#-------------------------------------------------------------------------------
# Old (check)

if ARGV[0] == 'destroy'
    deployer.destroy ARGV[1]
end

if ARGV[0] == 'deploy'
    deployer.deploy(ARGV[1])
end

if ARGV[0] == 'resethard'
    deployer.resethard
end

if ARGV[0] == 'restart'
    deployer.restart ARGV[1]
end
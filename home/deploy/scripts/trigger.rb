#! /bin/ruby

require '/home/deploy/scripts/single.rb'
deployer = DeploymentActions.new

if ARGV[0] == 'list'
    deployer.list
end

if ARGV[0] == 'create'
    deployer.create ARGV[1], ARGV[2], ARGV[3]
end

if ARGV[0] == 'destroy'
    deployer.destroy ARGV[1]
end

if ARGV[0] == 'deploy'
    deployer.deploy ARGV[1]
end
#! /bin/ruby

red = "\033[0;31m"
gre = "\033[0;32m"
yel = "\033[0;33m"
ncl = "\033[0m" #No colour

require 'erb'

appName = ARGV[0]

file = '/home/git/templates/hook.erb'
hookTemplate = ERB.new(File.read(file))

hook = hookTemplate.result(binding)
File.open("/home/git/repositories/#{appName}.git/hooks/post-update", 'w') {|f| f.write(hook) }

chmdFile = system( "chmod +x /home/git/repositories/#{appName}.git/hooks/post-update" )
if chmdFile == true
    puts "#{gre}Added post-update hook.#{ncl}"
else
    puts "#{red}Error - Could not make hook executable.#{ncl}"
    exit
end
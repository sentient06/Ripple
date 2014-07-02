# Ruby Deployment for Humans
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Nginx
  
  attr_accessor :still

  def initialize(templatesFolder, nginxAvailableFolder, nginxEnabledFolder)
    @put                  = Put.new
    @system               = System.new
    @templatesFolder      = templatesFolder
    @nginxAvailableFolder = nginxAvailableFolder
    @nginxEnabledFolder   = nginxEnabledFolder
    @still                = false
  end

  def start
    @put.normal "Starting Nginx"
    command = @system.execute( "sudo service nginx start" )
    if command.success?
      @put.confirm
      @still = false
    else
      @put.error "Could not start Nginx"
      exit
    end
  end

  def stop
    @put.normal "Stopping Nginx"
    command = @system.execute( "sudo service nginx stop" )
    if command.success?
      @put.confirm
      @still = true
    else
      @put.error "Could not stop Nginx"
      exit
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def availConfigFile(app)

    # Set variables for template:

    appUrl   = app["url"] #ERB
    appName  = app["name"]
    appPorts = app["ports"]
    upstream = ""

    appPorts.each {|value|
      upstream += "    server 127.0.0.1:#{value};\n"
    }

    # Saving file:
    @put.normal "Saving Nginx configuration file"

    file = "#{@templatesFolder}nginx.erb"
    nginxTemplate = ERB.new(File.read(file))
    nginxConfig = nginxTemplate.result(binding)
    nginxCommand = File.open("#{@nginxAvailableFolder}#{appName}.conf", 'w') {|f| f.write(nginxConfig) }

    unless nginxCommand.nil?
      @put.confirm
      return 0
    else
      @put.error "Could not save Nginx configuration"
      return 1
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def enableConfigFile(appName)

    nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
    nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"
    @put.normal "Checking Nginx config file"

    if File.exists?(nginxConfigFile)
      unless File.exists?(nginxConfigLink)
        @put.confirm
        @put.normal "Linking"
        action = @system.execute("ln -s #{nginxConfigFile} #{nginxConfigLink}")
        if action.success?
          @put.confirm
          return 0
        else
          @put.error "Could not symlink Nginx configuration file"
          return 1
        end
      end
    else
      @put.error "Config file non-existent"
      return 1
    end

  end

end
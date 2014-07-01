# Ruby Deployment for Humans
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Nginx
  
  def initialize(templatesFolder, nginxAvailableFolder, nginxEnabledFolder)
    @put                  = Put.new
    @system               = System.new
    @templatesFolder      = templatesFolder
    @nginxAvailableFolder = nginxAvailableFolder
    @nginxEnabledFolder   = nginxEnabledFolder
  end

  def start
    @put.normal "Starting Nginx"
    command = @system.execute( "sudo service nginx start" )
    if command.success?
      @put.confirm
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

    appPorts.each {|key, value|
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

end
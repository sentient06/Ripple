# Ruby Deployment for Humans
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Thin
  
  def initialize
    @put    = Put.new
    @system = System.new
    @thinPath = ENV["rvm_path"] + "/gems/" + ENV["RUBY_VERSION"] + "@ripple/bin/thin"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Starts Thin for an application
  #
  def start(appName)
    @put.normal "Starting thin for #{appName}"
    command = @system.execute( "#{@thinPath} start -C /etc/thin/#{appName}.yml" )
    if command.success?
      @put.confirm
    else
      @put.error "Could not start Thin"
      exit
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Stops Thin for an application
  #
  def stop(appName)
    @put.normal "Stopping thin for #{appName}"
    command = @system.execute( "#{@thinPath} stop -C /etc/thin/#{appName}.yml" )
    if command.success?
      @put.confirm
    else
      @put.error "Could not stop Thin"
      exit
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Saves Thin config file
  #
  def saveConfigFile(app)
    appName  = app["name"]
    appPorts = app["ports"]
    appFirst = appPorts[0]
    servers  = appPorts.count
    @put.normal "Saving Thin configuration for #{appName}"

    thinCommand = @system.execute("#{@thinPath} config -C /etc/thin/#{appName}.yml -c /var/www/#{appName} --servers #{servers} -e production -p #{appFirst}")
    if thinCommand.success?
      @put.confirm
      return 0
    else
      @put.error "Could not save Thin configuration for #{appName}"
      return 1
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes Thin config file
  #
  def deleteConfigFile(appName)
    @put.normal "Removing Thin configuration for #{appName}"
    configFile = "/etc/thin/#{appName}.yml"
    if File.exists?(configFile)
      removeCommand = @system.delete(configFile)
      if removeCommand.success?
        @put.confirm
        return 0
      else
        @put.error "Could not delete Thin configuration"
        return 1
      end
    else
      @put.error "Config file non-existent"
      return 1
    end
  end

end
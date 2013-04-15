# Ruby Deployment for Humans
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Thin
  
  def initialize
    @put    = Put.new
    @system = System.new
  end

  def start(appName)
    @put.normal "Starting thin for #{appName}"
    command = @system.execute( "thin start -C /etc/thin/#{appName}.yml" )
    if command.success?
      @put.confirm
    else
      @put.error "Could not start Thin"
      exit
    end
  end

  def stop(appName)
    @put.normal "Stopping thin for #{appName}"
    command = @system.execute( "thin stop -C /etc/thin/#{appName}.yml" )
    if command.success?
      @put.confirm
    else
      @put.error "Could not stop Thin"
      exit
    end
  end

end
# Ruby Deployment for Humans
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Nginx
  
  def initialize
    @put    = Put.new
    @system = System.new
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

end
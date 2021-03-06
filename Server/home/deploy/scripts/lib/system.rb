# Ripple
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class System

  attr_accessor :output

  def initialize
    @output = ""
  end
  
  # Returns a process object.
  # $? -> process, i.e #<Process::Status: pid 1612 exit 0>
  def execute(command, inPath = "", showOutput = false, user = "")
    su = ""
    unless su == ""
      su = "sudo -u #{user} "
    end
    if inPath != ""
      Dir.chdir "#{inPath}"
    end
    @output = `#{su}#{command} 2>&1`
    if showOutput
      puts @output
    end
    $?
  end

  def delete(path)
    execute("rm -f #{path}")
  end

  def deleteDir(path)
    execute("rm -rf #{path}")
  end

end
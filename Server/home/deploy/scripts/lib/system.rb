# Ruby Deployment for Humans
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class System
  # Returns a process object.
  # $? -> process, i.e #<Process::Status: pid 1612 exit 0>
  def execute(command, inPath = "", showOutput = false)
    if inPath != ""
      Dir.chdir "#{inPath}"
    end
    output = `#{command} 2>&1`
    if showOutput
      puts output
    end
    $?
  end

end
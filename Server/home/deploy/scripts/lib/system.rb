class System

  def initialize(command)
    execute(command)
  end

  # Returns a process object.
  def execute(command)
    # print "Executing '#{commandStr}'..."
    output = `#{commandStr} 2>&1`
    # $? -> process, i.e
    # #<Process::Status: pid 1612 exit 0>
    # #<Process::Status: pid 1620 exit 2>
    result = $?
  end
  
end
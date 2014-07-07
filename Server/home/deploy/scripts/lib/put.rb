# Ruby Deployment for Humans
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Put

  def initialize
    @red = "\033[0;31m"
    @gre = "\033[0;32m"
    @yel = "\033[0;33m"
    @blu = "\033[0;34m"
    @pur = "\033[0;35m"
    @cya = "\033[0;36m"
    @ncl = "\033[0m" #No colour
    @lastMsg = ''
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Static texts
  #
  def red(msg)
    puts "\n#{@red}#{msg}#{@ncl}\n"
  end

  def green(msg)
    puts "\n#{@gre}#{msg}#{@ncl}\n"
  end

  def yellow(msg)
    puts "\n#{@yel}#{msg}#{@ncl}\n"
  end

  def blue(msg)
    puts "\n#{@blu}#{msg}#{@ncl}\n"
  end

  def purple(msg)
    puts "\n#{@pur}#{msg}#{@ncl}\n"
  end

  def cyan(msg)
    puts "\n#{@cya}#{msg}#{@ncl}\n"
  end

  def noColour(msg)
    puts "\n#{@ncl}#{msg}#{@ncl}\n"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Flexible
  def static(msg)
    cyan(msg)
  end

  def feedback(msg)
    yellow("#{msg}\n")
  end

  # Saves message to update same line
  def normal(msg)
    print "#{@yel} ->  #{msg}...#{@ncl}"
    print "\r"
    @lastMsg = msg
  end

  # Updates normal output with success
  def confirm
    puts "#{@gre}[ok] #{@lastMsg}.  #{@ncl}"
  end

  # Updates normal output with error
  def error(msg)
    puts "\n#{@red}[Error] #{msg}!#{@ncl}\n"
  end

end
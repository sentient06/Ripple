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

  def static(msg)
    puts "\n#{@cya}#{msg}#{@ncl}\n"
  end

  def normal(msg)
    print "#{@yel} ->  #{msg}...#{@ncl}"
    print "\r"
    @lastMsg = msg
  end

  def confirm
    puts "#{@gre}[ok] #{@lastMsg}.  #{@ncl}"
  end

  def green(msg)
    puts "\n#{@gre}#{msg}#{@ncl}\n"
  end

  def error(msg)
    puts "\n#{@red}[Error] #{msg}!#{@ncl}\n"
  end

end
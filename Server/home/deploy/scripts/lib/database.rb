# Ripple
# Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Database

  def initialize
    
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Checks database's user's existence
  #
  def findUser(dbUser)
    action = @system.execute("sudo -u postgres psql -c '\\du' | grep #{dbUser}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates new database's user
  #
  def addUser(dbUser, dbPassword)
    action = @system.execute("echo \"CREATE ROLE #{dbUser} WITH LOGIN ENCRYPTED PASSWORD '#{dbPassword}';\" | sudo -u postgres psql")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Checks database's existence
  #
  def findDb(dbName)
    action = @system.execute("sudo -u postgres psql -c '\\l' | grep #{dbName}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates new database
  #
  def addDb(dbUser, dbName)
    action = @system.execute("sudo -u postgres createdb -O #{dbUser} #{dbName}")
    action.success?
  end

end
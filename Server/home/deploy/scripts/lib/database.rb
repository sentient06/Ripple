# Ripple
# Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Database

  def initialize(productionFolder)
    @put              = Put.new
    @system           = System.new
    @productionFolder = productionFolder
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

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Saves database to SQL dump file
  # http://www.postgresql.org/docs/current/static/backup.html
  #
  def sqlDump(appName, dbName)
    dbDumpFile = "/ripple/backup/#{appName}.gz"
    if File.exists?(dbDumpFile)
      @system.delete(dbDumpFile)
    end
    action = @system.execute("sudo -u postgres pg_dump #{dbName} | gzip > #{dbDumpFile}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copies database file for SQLite
  #
  def sqlite3Dump(appName)
    dbOriginalFile = "#{@productionFolder}#{appName}/db/production.sqlite3"
    dbDumpFile = "/ripple/backup/#{appName}.gz"
    if File.exists?(dbDumpFile)
      @system.delete(dbDumpFile)
    end
    action = @system.execute("gzip -c #{dbOriginalFile} > #{dbDumpFile}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Restores a SQL database
  #
  def sqlRestore(appName, dbName)
    @put.red "sqlRestore not implemented yet"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Restores a SQLite file
  #
  def sqlite3Restore(appName)
    @put.red "sqlite3Restore not implemented yet"
  end

end
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
  # Checks PostgreSQL database's user's existence
  #
  def findUserPG(dbUser)
    action = @system.execute("sudo -u postgres psql -c '\\du' | grep #{dbUser}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates new PostgreSQL database's user
  #
  def addUserPG(dbUser, dbPassword)
    action = @system.execute("echo \"CREATE ROLE #{dbUser} WITH LOGIN ENCRYPTED PASSWORD '#{dbPassword}';\" | sudo -u postgres psql")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Checks PostgreSQL database's existence
  #
  def findPG(dbName)
    action = @system.execute("sudo -u postgres psql -c '\\l' | grep #{dbName}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates new PostgreSQL database
  #
  def addPG(dbUser, dbName)
    action = @system.execute("sudo -u postgres createdb -O #{dbUser} #{dbName}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Saves database to PostgreSQL dump file
  # http://www.postgresql.org/docs/current/static/backup.html
  #
  def dumpPG(appName, dbName)
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
  def dumpS3(appName)
    dbOriginalFile = "#{@productionFolder}#{appName}/db/production.sqlite3"
    dbDumpFile = "/ripple/backup/#{appName}.gz"
    if File.exists?(dbDumpFile)
      @system.delete(dbDumpFile)
    end
    action = @system.execute("gzip -c #{dbOriginalFile} > #{dbDumpFile}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Restores a PostgreSQL database
  #
  def restorePG(appName, dbName)
    # @put.red "restorePG not implemented yet"
    # gunzip -c filename.gz | psql dbname
    backupFile = "/ripple/backup/#{appName}.gz"
    action = @system.execute("gunzip -c #{backupFile} | sudo -u postgres psql #{dbName}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Restores a SQLite file
  #
  def restoreS3(appName)
    dbBackup = "/ripple/backup/#{appName}.gz"
    dbOriginal = "#{@productionFolder}#{appName}/db/production.sqlite3"
    if File.exists?(dbOriginal)
      @system.delete(dbOriginal)
    end
    action = @system.execute("gzip -dc #{dbBackup} > #{dbOriginal}")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes a SQLite file
  #
  def deleteS3(appName)
    dbOriginalFile = "#{@productionFolder}#{appName}/db/production.sqlite3"
    if File.exists?(dbOriginalFile)
      success = @system.delete(dbOriginalFile)
      return success
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes a PostgreSQL database
  #
  def deletePG(appName, dbName, dbUser)
    # DROP USER [ IF EXISTS ] name [, ...]
    # DROP DATABASE [IF EXISTS] name;
    # ALTER DATABASE "databaseName" RENAME TO "databaseNameOld"
    query = "DROP DATABASE #{dbName}"
    action = @system.execute("echo \"#{query};\" | sudo -u postgres psql")
    unless action.success?
      @put.error "Could not drop database (#{dbName})"
    else
      query = "DROP USER #{dbUser}"
      action = @system.execute("echo \"#{query};\" | sudo -u postgres psql")
      unless action.success?
        @put.error "Could not drop db user (#{dbUser})"
      else
        return true
      end
    end
    # action.success?
    # @put.red "deletePG not implemented yet"
    # return false
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copies the file from bot to Ripple dir
  #
  def transferDB(appName)
    originPath = "/home/bot/backup/#{appName}.gz"
    destinyPath = "/ripple/backup/#{appName}.gz"
    @system.execute "cp #{originPath} #{destinyPath}"
    @system.delete(originPath)
    @system.execute "chmod 644 #{destinyPath}"
  end

end
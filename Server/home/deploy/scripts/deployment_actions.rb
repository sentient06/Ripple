# deployment_actions.rb
# Ruby Deployment for Humans
#
# Created by Giancarlo Mariot on 02/01/2013.
# Copyright (c) 2012 Giancarlo Mariot. All rights reserved.
#
#------------------------------------------------------------------------------
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#------------------------------------------------------------------------------

# Conventions:
# http://pub.cozmixng.org/~the-rwiki/rw-cgi.rb?cmd=view;name=RubyCodingConvention
# http://www.caliban.org/ruby/rubyguide.shtml

# Note: Check if Thin is in the Gemfile

# @apps[appName]["url"]        # application dns
# @apps[appName]["ports"]      # quantity of thin ports
# @apps[appName]["first"]      # first port, from 3000
# @apps[appName]["repository"] # repository created
# @apps[appName]["thin"]       # thin configuration
# @apps[appName]["available"]  # nginx available config
# @apps[appName]["enabled"]    # nginx enabled config
# @apps[appName]["db"]         # existing database
# @apps[appName]["online"]     # servers on

# List    - none
# Create  - url, ports, first, repository
# Deploy  - thin, available, enabled, db, online
# Stop    - thin, available, enabled, db, online
# Destroy - url, ports, first, repository

require 'erb'
require 'yaml'

class DeploymentActions

  def initialize

    @red = "\033[0;31m"
    @gre = "\033[0;32m"
    @yel = "\033[0;33m"
    @blu = "\033[0;34m"
    @pur = "\033[0;35m"
    @cya = "\033[0;36m"
    @ncl = "\033[0m" #No colour

    @deployerUser = "deploy"
    @gitUser      = "git"

    @dataFile             = "/home/#{@deployerUser}/data/apps"
    @repositoriesFolder   = "/home/#{@gitUser}/repositories/"
    @templatesFolder      = "/home/#{@deployerUser}/templates/"
    @productionFolder     = "/var/www/"
    @databaseYml          = "/config/database.yml"
    @nginxAvailableFolder = "/etc/nginx/sites-available/"
    @nginxEnabledFolder   = "/etc/nginx/sites-enabled/"

    @stop = false

    loadData

  end

  #-------------------------------------------------------------------------------
  # Getters to use on IRB

  def vars
    puts "dataFile\nrepositoriesFolder\ntemplatesFolder\nproductionFolder\ndatabaseYml\nlastMsg\napps"
  end

  def dataFile
    @dataFile
  end

  def repositoriesFolder
    @repositoriesFolder
  end

  def templatesFolder
    @templatesFolder
  end

  def productionFolder
    @productionFolder
  end

  def databaseYml
    @databaseYml
  end

  def lastMsg
    @lastMsg
  end

  def apps
    @apps
  end

  #-------------------------------------------------------------------------------
  # Print methods

  def ptNormal(msg)

    print "#{@yel}#{msg}...#{@ncl}\n"
    # print "\r"
    @lastMsg = msg

  end

  def ptConfirm

    puts "#{@gre}#{@lastMsg}. [ok]#{@ncl}"

  end

  def ptGreen(msg)

    puts "\n#{@gre}#{msg}#{@ncl}\n"

  end

  def ptError(msg)

    puts "\n#{@red}[Error] #{msg}!#{@ncl}\n"

  end

  #-------------------------------------------------------------------------------
  # System actions

  # Returns a process object.
  def systemCmd(commandStr)

    print "Executing '#{commandStr}'..."
    output = `#{commandStr} 2>&1`
    # $? -> process, i.e
    # #<Process::Status: pid 1612 exit 0>
    # #<Process::Status: pid 1620 exit 2>
    result = $?

  end

  #-------------------------------------------------------------------------------
  # File methods

  def loadData

    unless File.exists?(@dataFile)
      @apps = Hash.new
      print "\r"
      ptNormal("List of apps unavailable")
    else
      @apps = Marshal.load File.read(@dataFile)
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def saveData
    serialisedApps = Marshal.dump(@apps)
    savedFile = File.open(@dataFile, 'w') {|f| f.write(serialisedApps) }
    if savedFile.nil?
      ptError("Something went wrong saving the data file")
      return 1
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def resetApplicationData

    port = 3000

    # Iterates through all apps to store correct ports:

    @apps.each {|key, value|
      value["ports"].times do |i|
        if i == 0
          value["first"] = port
        end
        puts "#{@gre} - Port #{port} - #{key}#{@ncl}"
        port += 1
      end
    }

    saveData

  end

  #---------------------------------------------------------------------------
  # Secondary methods

  def createRepository(appName)

    # Checks for repository:

    repositoryFolder = "#{@repositoriesFolder}#{appName}.git"

    if File.exists?(repositoryFolder)
      ptError "Repository folder already exists"
      return
    end

    # Creates folder:

    ptNormal "Creating repository folder for #{appName}"

    createFolder = systemCmd("sudo -u #{@gitUser} mkdir #{repositoryFolder}")

    if createFolder.success?
      ptConfirm
    else
      ptError "Could not create git folder"
      @stop = true
      return      
    end

    # Creates git bare respository

    ptNormal "Creating bare repository for #{appName}"

    createGit = systemCmd("sudo -u #{@gitUser} git init #{repositoryFolder}/ --bare")

    if createGit.success?
      ptConfirm
    else
      ptError "Could not create git repository"
      @stop = true
      return
    end

    # Saves the post-update hook:

    ptNormal "Creating hooks for #{appName}"

    createHook = systemCmd("sudo -u #{@gitUser} /usr/local/rvm/bin/ruby /home/#{@gitUser}/scripts/createHook.rb #{appName}")

    if createHook.success?
      ptConfirm
    else
      print "\n"
      ptError "Could not create hook"
      @stop = true
      return
    end

    @apps[appName]["repository"] = true
    saveData

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def cloneRepository(appName)

    ptNormal "Cloning repository for #{appName}"

    # Cloning:

    # require 'open3'
    cloneGit = systemCmd( "git clone #{@repositoriesFolder}#{appName}.git #{@productionFolder}#{appName}" )
    # @stdin, @stdout, @stderr = Open3.popen3('git clone', "#{@repositoriesFolder}#{appName}.git", "#{@productionFolder}#{appName}")
    # @stdout.gets(nil)
    # @stderr.gets(nil)

    # @stdin.close
    # @stdout.close
    # @stderr.close

    if cloneGit.success?
      ptConfirm
    else
      ptError "Repository could not be cloned"
      @stop = true
      return
    end

    # Permissions to 775:

    ptNormal "Changing repository's permissions"

    cloneGit = systemCmd("chmod -R 775 #{@productionFolder}#{appName}")

    if cloneGit.success?
      ptConfirm
    else
      ptError "Could not change repository's permissions"
      @stop = true
      return
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def availNginxConfigFile(appName)

    # Set variables for template:

    appUrl   = @apps[appName]["url"] #ERB
    appPorts = @apps[appName]["ports"]
    appFirst = @apps[appName]["first"]
    upstream = ""

    appPorts.times do |i|
      upstream += "    server 127.0.0.1:#{appFirst+i};\n"
    end

    # Saving file:

    ptNormal "Saving Nginx configuration"

    file = "#{@templatesFolder}nginx.erb"
    nginxTemplate = ERB.new(File.read(file))
    nginxConfig = nginxTemplate.result(binding)
    nginxCommand = File.open("#{@nginxAvailableFolder}#{appName}.conf", 'w') {|f| f.write(nginxConfig) }

    unless nginxCommand.nil?
      ptConfirm
    else
      ptError "Could not save Nginx configuration"
      return
    end

    @apps[appName]["available"] = true
    saveData 

  end

  def enableNginxConfigFile(appName)

    nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
    nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"
    ptNormal "Checking Nginx config file"

    if File.exists?(nginxConfigFile)
      unless File.exists?(nginxConfigLink)
        ptConfirm
        action = systemCmd("ln -s #{nginxConfigFile} #{nginxConfigLink}")
        unless action.success?
          ptError "Could not symlink Nginx configuration file"
          return
        end
      end
    else
      ptError "Config file non-existent"
      return
    end

    @apps[appName]["enabled"] = false
    saveData

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleteNginxConfigFile(appName)

    nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
    nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"

    if File.exists?(nginxConfigLink)
      ptNormal "Deleting symlink for #{appName}"
      nginxCmd1 = systemCmd("rm #{nginxConfigLink}")

      if nginxCmd1.success?
        @apps[appName]["enabled"] = false
        saveData
        ptConfirm
      else
        ptError "Could not delete configuration symlink for #{appName}"
        return
      end
    else
      ptGreen "No symlink found."
    end

    if File.exists?(nginxConfigFile)

      ptNormal "Deleting Nginx configuration for #{appName}"
      nginxCmd2 = systemCmd("rm #{nginxConfigFile}")

      if nginxCmd2.success?
        @apps[appName]["available"] = false
        saveData
        ptConfirm
      else
        ptError "Could not delete configuration file for #{appName}"
        return
      end

    else
      ptGreen "No config file found."
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  def saveThinConfigFile(appName)

    ptNormal "Saving Thin configuration for #{appName}"
    appPorts = @apps[appName]["ports"]
    appFirst = @apps[appName]["first"]
    thinCommand = systemCmd("thin config -C /etc/thin/#{appName}.yml -c /var/www/#{appName} --servers #{appPorts} -e production -p #{appFirst}")

    if thinCommand.success?
      ptConfirm
    else
      ptError "Could not save Thin configuration for #{appName}"
      return
    end

    @apps[appName]["thin"] = true
    saveData

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleteThinConfigFile(appName)

    ptNormal "Deleting Thin configuration for #{appName}"
    thinCmd = systemCmd("rm /etc/thin/#{appName}.yml")

    if thinCmd.success?
      ptConfirm
    else
      ptError "Could not delete Thin configuration for #{appName}"
      return
    end

    @apps[appName]["thin"] = false
    saveData

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def startNginx
    actionNginx = systemCmd( "sudo service nginx start" )
    unless actionNginx.success?
      ptError "Could not start Nginx"
      return
    else
      # ptConfirm
    end
  end

  def stopNginx
    # ptNormal "Stopping Nginx"
    command = systemCmd( "sudo service nginx stop" )
    unless command.success?
      ptError "Could not stop Nginx"
      return
    else
      # ptConfirm
    end
  end

  def startThin(appName)
    command = systemCmd( "thin start -C /etc/thin/#{appName}.yml" )
    unless command.success?
      ptError "Could not start Thin"
      return
    else
      # ptConfirm
    end
  end

  def stopThin(appName)
    command = systemCmd( "thin stop -C /etc/thin/#{appName}.yml" )
    unless command.success?
      ptError "Could not stop Thin"
      return
    else
      # ptConfirm
    end
  end

  def resetServers

    ptNormal "Restarting servers"
    stopServers
    startServers

  end

  def stopServers

    stopNginx
    ptNormal "Stopping Thin"

    # Iterates through all apps to stop server instances:

    @apps.each {|key, value|
      if value["online"]
        command = systemCmd("thin stop -C /etc/thin/#{key}.yml")
      end
    }

  end

  def startServers

    ptNormal "Starting servers"
    ptNormal "Starting Thin"

    @apps.each {|key, value|
      if value["online"]
        command = systemCmd( "thin start -C /etc/thin/#{key}.yml" )
      end
    }

    startNginx

  end

  #---------------------------------------------------------------------------
  # Database methods

  def checkDbUser(dbUser)
    action = systemCmd("sudo -u postgres psql -c '\\du' | grep #{dbUser}")
  end

  def createDbUser(dbUser, dbPassword)
    action = systemCmd("echo \"CREATE ROLE #{dbUser} WITH LOGIN ENCRYPTED PASSWORD '#{dbPassword}';\" | sudo -u postgres psql")
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def checkDb(dbName)
    dbExists = systemCmd("sudo -u postgres psql -c '\\l' | grep #{dbName}")
  end

  def createProductionDb(dbUser, dbName)
    action = systemCmd("sudo -u postgres createdb -O #{dbUser} #{dbName}")
  end

  #---------------------------------------------------------------------------
  # Action methods

  def test
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  # Lists all applications names, ports used and url.
  #
  def list
    # Iterate through all apps and print

    len    = 15
    bigKey = @apps.keys.max { |a, b| a.length <=> b.length }
    len    = bigKey.length

    print "\nList of applications\n--------------------\n"

    @apps.each {|key, value|
      printf(" [#{@gre}%-#{len}s#{@ncl}] - #{@gre}%2d#{@ncl} ports starting on #{@gre}%4d#{@ncl}, url: #{@gre}%s#{@ncl}\n", key.to_s, value['ports'], value['first'], value['url'])
    }

    print "\n"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  #
  def appStatus(appName)

    print @apps[appName]
    print "\nURL ........... "
    print @apps[appName]["url"]
    print "\nPorts ......... "
    print @apps[appName]["ports"]
    print "\nFirst port .... "
    print @apps[appName]["first"]
    print "\nRepository .... "
    print @apps[appName]["repository"]
    print "\nThin config ... "
    print @apps[appName]["thin"]
    print "\nAvailable ..... "
    print @apps[appName]["available"]
    print "\nEnabled ....... "
    print @apps[appName]["enabled"]
    print "\nDatabase ...... "
    print @apps[appName]["db"]
    print "\nOnline ........ "
    print @apps[appName]["online"]

    print "\n"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates a new application
  #
  def create(appName, appURL, appPorts)
    
    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Check for errors:

    if appName.nil?
      ptError "Define a name to create this application"
      return
    end

    if appURL.nil?
      ptError "Define an URL to create this application"
      return
    end

    if appPorts.nil?
      appPorts = 1
    end

    unless @apps[appName].nil?
      ptError "There is already an app with this name"
      return
    end

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Create empty application:

    @apps[appName]               = Hash.new
    @apps[appName]["url"]        = appURL        # application dns - Test with an array
    @apps[appName]["ports"]      = appPorts.to_i # quantity of thin ports
   #@apps[appName]["first"]      = 3000 + x
    @apps[appName]["repository"] = false  # repository created
    @apps[appName]["thin"]       = false  # thin configuration
    @apps[appName]["available"]  = false  # nginx available config
    @apps[appName]["enabled"]    = false  # nginx enabled config
    @apps[appName]["db"]         = false  # existing database
    @apps[appName]["online"]     = false  # online

    saveData

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Set git repository for deployment:

    resetApplicationData     # set 'first'
    createRepository appName # set 'repository'

    if @stop == true
      return
    end

    # Clone repository for further use:

    cloneRepository appName

    if @stop == true
      return
    end

    # Save server configurations:

    availNginxConfigFile appName # available (should enable at deployment only)
    saveThinConfigFile appName   # thin

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Check database information and create it if needed
  #
  def deployDatabase(appName)

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Check data:

    if @apps[appName]["db"] == true
      ptGreen "Database already set. Nothing to do here."
      return
    end

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Check DB information on application:

    dbConfigFile = "#{@productionFolder}#{appName}#{@databaseYml}"

    ptNormal "Checking DB file: #{dbConfigFile}"

    unless File.exists?(dbConfigFile)
      ptError "Database file does not exist"
      @stop = true
      return
    end

    dbDetails = YAML.load_file(dbConfigFile)

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Load information:

    productionDB = dbDetails['production']
    ptNormal "Production db details:"
    puts productionDB

    if productionDB.nil?
      ptNormal "Nothing to do with the database"
      return
    end

    dbAdapter = productionDB['adapter']

    # If this is a SQLite 3, accept it:

    if dbAdapter == "sqlite3"
      ptGreen "Sqlite3 detected!"
      @apps[appName]["db"] = true
      saveData
      return
    end

    # If PostgreSQL, go on:

    dbName = productionDB['database']
    dbUser = productionDB['username']
    dbPass = productionDB['password']

    if dbPass.nil?
      ptNormal "No password, ignoring database"
      @stop = true
      return
    end

    ptNormal "Name: #{dbName}"
    ptNormal "User: #{dbUser}"
    ptNormal "Pass: #{dbPass}"

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Checking user:

    ptNormal "Checking DB user existence"
    userExistent = checkDbUser dbUser

    unless userExistent

      ptConfirm
      ptNormal "Creating new user '#{dbUser}'"

      newUser = createDbUser dbUser, dbPass
      unless newUser
        ptError "Unable to create DB user"
        @stop = true
        return
      else
        userExistent = true
        ptConfirm
      end

    else
      ptConfirm
    end

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Checking database:

    ptNormal "Checking DB existence"
    dbExistent = checkDb dbName

    unless dbExistent

      ptConfirm
      ptNormal "Creating new database"

      newDB = createProductionDb(dbUser, dbName)
      unless newDB
        ptError "Unable to create database"
        @stop = true
        return
      else
        dbExistent = true
        ptConfirm
      end

    else
        ptConfirm
    end

    if userExistent && dbExistent
      @apps[appName]["db"] = true
      saveData
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deploy application
  #
  def deploy(appName)

    ptGreen "[Checking data]"

    if @apps[appName]["repository"]
      if @apps[appName]["thin"]
        if @apps[appName]["available"]
          ptGreen "All seems to be fine, yay!"
        else
          ptError "Nginx configuration not saved"
          return
        end
      else
        ptError "Thin configuration not saved"
        return
      end
    else
      ptError "Repository non-existent"
      return
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    puts @apps[appName]

    # If already online, stop thin.

    if @apps[appName]["online"]
      stopNginx
      stopThin(appName)
      startNginx
      @apps[appName]["online"] = false
      saveData
    end

    # Deploy database

    ptNormal "[Checking database]"

    if @apps[appName]["db"] == false
      deployDatabase appName
      if @stop == true
        return
      end
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    ptGreen "[Deploying]"
    Dir.chdir "#{@productionFolder}#{appName}"

    ptNormal "Executing 'bundle package'"
    deployStep2 = systemCmd("bundle package")

    if deployStep2.success?
      ptConfirm
    else
      ptError "Could not deploy step 2 - bundle package"
      return
    end

    ptNormal "Executing 'bundle install'"
    deployStep3 = systemCmd("bundle install --deployment")

    if deployStep3.success?
      ptConfirm
    else
      ptError "Could not deploy step 3 - bundle install"
      return
    end

    # Check for migrations!

    migrationsFolder = "#{@productionFolder}#{appName}/db/migrate/"
    migrationsNumber = Dir.glob(File.join(migrationsFolder, '**', '*.rb')).count

    if migrationsNumber > 0
      ptNormal "#{migrationsNumber} migrations found."
      ptNormal "Migrating"

      deployStep4 = systemCmd("RAILS_ENV=production rake db:migrate")
      
      if deployStep4.success?
        ptConfirm
      else
        ptError "Could not deploy step 4 - database migrate"
        return
      end

    end

    ptNormal "Precompile assets"
    deployStep5 = systemCmd("rake assets:precompile")

    if deployStep5.success?
      ptConfirm
    else
      ptError "Could not deploy step 5 - assets precompile"
      return
    end

    # If all is fine, start thin, restart nginx.

    stopNginx
    startThin appName
    startNginx

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Rewrites the config files and resets thin
  #
  def reset(appName)

    if @apps[appName]["online"]
      stopThin(appName)
    end

    deleteNginxConfigFile(appName)
    deleteThinConfigFile(appName)
    saveThinConfigFile
    availNginxConfigFile
    enableNginxConfigFile

    if @apps[appName]["online"]
      startThin(appName)
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Rewrites the config files and resets the servers
  #
  def resetAll

    stopNginx
    resetApplicationData
    @apps.each {|key, value|
        reset(key)
    }
    startNginx

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Sets new value in the apps hash
  #
  def set(appName, key, value)

    @apps[appName][key] = value
    saveData
    resetAll

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes configuration files and stops the application
  #
  def disable(appName)
    stopNginx
    stopThin(appName)
    deleteNginxConfigFile(appName)
    deleteThinConfigFile(appName)
    startNginx
    @apps[appName]["online"] = false
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def destroydb
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def destroy(appName)
    disable appName
    action = systemCmd( "rm -rf #{@productionFolder}#{appName} && sudo -u git rm -rf #{@repositoriesFolder}#{appName}.git" )

    if action.success?
      @apps.delete(appName)
      saveData
      ptGreen "#{appName.capitalize} destroyed!"
    else
      ptError "Problem trying to destroy #{appName}."
    end
  end

  #

  # def resethard
  #   system( "rm -rf #{@productionFolder}*" )
  #   system( "rm -rf #{@productionFolder}*" )
  # end

end
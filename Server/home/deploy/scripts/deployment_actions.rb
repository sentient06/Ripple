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

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }

class DeploymentActions

  def initialize

    @red = "\033[0;31m"
    @gre = "\033[0;32m"
    @yel = "\033[0;33m"
    @blu = "\033[0;34m"
    @pur = "\033[0;35m"
    @cya = "\033[0;36m"
    @ncl = "\033[0m" #No colour

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Loads information from YML file:

    generalDataFile = File.join(File.dirname(File.expand_path(__FILE__)), 'general.yml')

    if File.exists?(generalDataFile)
      generalData = YAML.load_file(generalDataFile)
    else
      @put.error "Unable to read general data file."
      exit
    end

    @deployerUser         = generalData['deployerUser']
    @gitUser              = generalData['gitUser']
    @dataFile             = generalData['dataFile']
    @repositoriesFolder   = generalData['repositoriesFolder']
    @templatesFolder      = generalData['templatesFolder']
    @productionFolder     = generalData['productionFolder']
    @databaseYml          = generalData['databaseYml']
    @nginxAvailableFolder = generalData['nginxAvailableFolder']
    @nginxEnabledFolder   = generalData['nginxEnabledFolder']

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    @system = System.new
    @put    = Put.new
    @nginx  = Nginx.new
    @thin   = Thin.new

    @dashes = '----------------------'

    loadData

  end

  #-------------------------------------------------------------------------------
  # Getters to use on IRB

  def vars
    puts "dataFile\nrepositoriesFolder\ntemplatesFolder\nproductionFolder\ndatabaseYml\nlastMsg\napps"
  end

  attr_reader :dataFile, :repositoriesFolder, :templatesFolder, :productionFolder, :databaseYml, :lastMsg, :apps

  #-------------------------------------------------------------------------------
  # File methods

  def loadData

    unless File.exists?(@dataFile)
      @apps = Hash.new
      @put.green "List of apps unavailable."
    else
      @apps = Marshal.load File.read(@dataFile)
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def saveData
    serialisedApps = Marshal.dump(@apps)
    savedFile = File.open(@dataFile, 'w') {|f| f.write(serialisedApps) }
    if savedFile.nil?
      @put.error("Something went wrong saving the data file")
      exit
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def resetApplicationData

    port = 3000

    @put.normal "Setting ports"
    thinConfigChange = Array.new
    nginxConfigChange = Array.new

    # Iterates through all apps to store correct ports:
    @apps.each {|key, value|
      value["ports"].times do |i|
        print "\r"
        if i == 0
          
          if value["first"] != port
            value["first"] = port
            if value["thin"] == true
              thinConfigChange.push(value['name'])
            end
            if value["available"] == true
              nginxConfigChange.push(value['name'])
            end
          end

        end
        # puts "#{@gre} - Port #{port} - #{key}#{@ncl}"
        port += 1
      end
    }

    @put.confirm
    saveData

    return

    # to test:

    if thinConfigChange.length > 0
      thinConfigChange.each { |app|
        saveThinConfigFile(app)
      }
    end

    if nginxConfigChange.length > 0
      nginxConfigChange.each { |app|
        availNginxConfigFile(app)
      }
    end

  end

  #---------------------------------------------------------------------------
  # Secondary methods

  def createRepository(appName, createHook=true)

    # Checks for repository:

    repositoryFolder = "#{@repositoriesFolder}#{appName}.git"

    if File.exists?(repositoryFolder)
      @put.error "Repository folder already exists"
      return
    end

    # Creates folder:

    @put.normal "Creating repository folder for #{appName}"

    createFolder = @system.execute("sudo -u #{@gitUser} mkdir #{repositoryFolder}")

    if createFolder.success?
      @put.confirm
    else
      @put.error "Could not create git folder"
      exit     
    end

    # Creates git bare respository

    @put.normal "Creating bare repository for #{appName}"

    createGit = @system.execute("sudo -u #{@gitUser} git init #{repositoryFolder}/ --bare")

    if createGit.success?
      @put.confirm
    else
      @put.error "Could not create git repository"
      exit
    end

    # Saves the post-update hook:
    if createHook==true
      @put.normal "Creating hooks for #{appName}"

      createHook = @system.execute("sudo -u #{@gitUser} /usr/local/rvm/bin/ruby /home/#{@gitUser}/scripts/createHook.rb #{appName}")

      if createHook.success?
        @put.confirm
      else
        print "\n"
        @put.error "Could not create hook"
        exit
      end
    end

    @apps[appName]["repository"] = true
    saveData

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def cloneRepository(appName)

    @put.normal "Cloning repository for #{appName}"

    # Cloning:
    cloneGit = @system.execute( "git clone #{@repositoriesFolder}#{appName}.git #{@productionFolder}#{appName}" )

    if cloneGit.success?
      @put.confirm
    else
      @put.error "Repository could not be cloned"
      exit
    end

    # Permissions to 775:

    @put.normal "Changing repository's permissions"

    cloneGit = @system.execute("chmod -R 775 #{@productionFolder}#{appName}")

    if cloneGit.success?
      @put.confirm
    else
      @put.error "Could not change repository's permissions"
      exit
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

    @put.normal "Saving Nginx configuration file"

    file = "#{@templatesFolder}nginx.erb"
    nginxTemplate = ERB.new(File.read(file))
    nginxConfig = nginxTemplate.result(binding)
    nginxCommand = File.open("#{@nginxAvailableFolder}#{appName}.conf", 'w') {|f| f.write(nginxConfig) }

    unless nginxCommand.nil?
      @put.confirm
    else
      @put.error "Could not save Nginx configuration"
      return
    end

    @apps[appName]["available"] = true
    saveData 

  end

  def enableNginxConfigFile(appName)

    nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
    nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"
    @put.normal "Checking Nginx config file"

    if File.exists?(nginxConfigFile)
      unless File.exists?(nginxConfigLink)
        @put.confirm
        @put.normal "Linking"
        action = @system.execute("ln -s #{nginxConfigFile} #{nginxConfigLink}")
        if action.success?
          @put.confirm
          @apps[appName]["enabled"] = true
          saveData
        else
          @put.error "Could not symlink Nginx configuration file"
        end
      end
    else
      @put.error "Config file non-existent"
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def disableNginxConfigFile(appName)

    nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
    nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"

    if File.exists?(nginxConfigLink)
      @put.normal "Deleting symlink for #{appName}"
      nginxCmd1 = @system.execute("rm #{nginxConfigLink}")

      if nginxCmd1.success?
        @apps[appName]["enabled"] = false
        @put.confirm
        saveData
      else
        @put.error "Could not delete configuration symlink for #{appName}"
      end

    else
      @put.green "No symlink found."
    end

  end

  def deleteNginxConfigFile(appName) #hinder?

    disableNginxConfigFile(appName)

    nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"

    if File.exists?(nginxConfigFile)

      @put.normal "Deleting Nginx configuration for #{appName}"
      nginxCmd2 = @system.execute("rm #{nginxConfigFile}")

      if nginxCmd2.success?
        @apps[appName]["available"] = false
        saveData
        @put.confirm
      else
        @put.error "Could not delete configuration file for #{appName}"
        return
      end

    else
      @put.green "No config file found."
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  def saveThinConfigFile(appName)

    @put.normal "Saving Thin configuration for #{appName}"
    appPorts = @apps[appName]["ports"]
    appFirst = @apps[appName]["first"]
    thinCommand = @system.execute("thin config -C /etc/thin/#{appName}.yml -c /var/www/#{appName} --servers #{appPorts} -e production -p #{appFirst}")

    if thinCommand.success?
      @put.confirm
    else
      @put.error "Could not save Thin configuration for #{appName}"
      return
    end

    @apps[appName]["thin"] = true
    saveData

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def deleteThinConfigFile(appName)

    @put.normal "Deleting Thin configuration for #{appName}"
    thinCmd = @system.execute("rm /etc/thin/#{appName}.yml")

    if thinCmd.success?
      @put.confirm
    else
      @put.error "Could not delete Thin configuration for #{appName}"
      return
    end

    @apps[appName]["thin"] = false
    saveData

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def startNginx
    @nginx.start
  end

  def stopNginx
    @nginx.stop
  end

  # Relocating to Thin class

  def startThin(appName)
    @put.normal "Starting thin for #{appName}"
    command = @system.execute( "thin start -C /etc/thin/#{appName}.yml" )
    if command.success?
      @put.confirm
    else
      @put.error "Could not start Thin"
      exit
    end
    # @thin.start(appName)
  end

  # Relocating to Thin class

  def stopThin(appName)
    @put.normal "Stopping thin for #{appName}"
    command = @system.execute( "thin stop -C /etc/thin/#{appName}.yml" )
    if command.success?
      @put.confirm
    else
      @put.error "Could not stop Thin"
      exit
    end
    # @thin.stop(appName)
  end

  def startApp(appName)
    @nginx.stop
    startThin(appName)
    @nginx.start
    @apps[appName]["online"] = true
    saveData
  end

  def stopApp(appName)
    @nginx.stop
    stopThin(appName)
    @nginx.start
    @apps[appName]["online"] = false
    saveData
  end

  def resetServers
    @put.normal "Restarting servers"
    stopServers
    startServers
  end

  def stopServers

    @nginx.stop
    @put.normal "Stopping Thin"

    # Iterates through all apps to stop server instances:

    @apps.each {|key, value|
      if value["online"]
        command = @system.execute("thin stop -C /etc/thin/#{key}.yml")
      end
    }

  end

  def startServers

    @put.normal "Starting servers"
    @put.normal "Starting Thin"

    @apps.each {|key, value|
      if value["online"]
        command = @system.execute( "thin start -C /etc/thin/#{key}.yml" )
      end
    }

    @nginx.start

  end

  #---------------------------------------------------------------------------
  # Database methods

  def checkDbUser(dbUser)
    action = @system.execute("sudo -u postgres psql -c '\\du' | grep #{dbUser}")
    action.success?
  end

  def createDbUser(dbUser, dbPassword)
    action = @system.execute("echo \"CREATE ROLE #{dbUser} WITH LOGIN ENCRYPTED PASSWORD '#{dbPassword}';\" | sudo -u postgres psql")
    action.success?
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def checkDb(dbName)
    action = @system.execute("sudo -u postgres psql -c '\\l' | grep #{dbName}")
    action.success?
  end

  def createProductionDb(dbUser, dbName)
    action = @system.execute("sudo -u postgres createdb -O #{dbUser} #{dbName}")
    action.success?
  end

  #---------------------------------------------------------------------------
  # Action methods

  def test

    print "\n"
    print "#{@cya}Printing global variables#{@ncl}\n"
    print "#{@cya}-------------------------#{@ncl}\n"
    print "#{@cya}DeployerUser         = #{@gre}#{@deployerUser}#{@ncl}\n"
    print "#{@cya}GitUser              = #{@gre}#{@gitUser}#{@ncl}\n"
    print "#{@cya}DataFile             = #{@gre}#{@dataFile}#{@ncl}\n"
    print "#{@cya}RepositoriesFolder   = #{@gre}#{@repositoriesFolder}#{@ncl}\n"
    print "#{@cya}TemplatesFolder      = #{@gre}#{@templatesFolder}#{@ncl}\n"
    print "#{@cya}ProductionFolder     = #{@gre}#{@productionFolder}#{@ncl}\n"
    print "#{@cya}DatabaseYml          = #{@gre}#{@databaseYml}#{@ncl}\n"
    print "#{@cya}NginxAvailableFolder = #{@gre}#{@nginxAvailableFolder}#{@ncl}\n"
    print "#{@cya}NginxEnabledFolder   = #{@gre}#{@nginxEnabledFolder}#{@ncl}\n"
    print "\n"
    print "#{@cya}Executing system commands#{@ncl}\n"
    print "#{@cya}-------------------------#{@ncl}\n"
    print "whoami ............... "
    system("whoami")
    print "sudo -u git whoami ... "
    system("sudo -u git whoami")
    # print "rvmsudo echo 2013 .... "
    # system("rvmsudo echo 2013")
    print "\n"

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  # Lists all applications names, ports used and url.
  #
  def list

    if @apps.count < 1
      @put.green "No applications found."
      exit
    end

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
  # Creates a new application
  #
  def create(appName, appURL, appPorts)
    
    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Check for errors:

    if appName.nil?
      @put.error "Define a name to create this application"
      exit
    end

    if appURL.nil?
      @put.error "Define an URL to create this application"
      exit
    end

    if appPorts.nil?
      appPorts = 1
    end

    unless @apps[appName].nil?
      @put.error "There is already an app with this name"
      exit
    end

    dashes = "-----------------------"
    print "\n#{@cya}Creating application '#{appName}'\n"
    print dashes[0, appName.length]
    print "#{dashes}\n"

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

    # Clone repository for further use:

    cloneRepository appName

    # Save server configurations:

    availNginxConfigFile appName # available (should enable at deployment only)
    saveThinConfigFile appName   # thin

    print "\n"

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  # Prints details about a given application.
  #
  def appStatus(appName)

    dashes = '----------------------'

    print "\n#{@gre}#{appName.capitalize} application's details\n"
    print dashes[0, appName.length]
    print "#{dashes}\n"
    print "\n#{@ncl}URL .............. #{@gre}"
    print @apps[appName]["url"]
    print "\n#{@ncl}Ports ............ #{@gre}"
    print @apps[appName]["ports"]
    print "\n#{@ncl}First port ....... #{@gre}"
    print @apps[appName]["first"]
    print "\n#{@ncl}Repository ....... #{@gre}"
    print @apps[appName]["repository"]
    print "\n#{@ncl}Thin config ...... #{@gre}"
    print @apps[appName]["thin"]
    print "\n#{@ncl}Nginx available .. #{@gre}"
    print @apps[appName]["available"]
    print "\n#{@ncl}Nginx enabled .... #{@gre}"
    print @apps[appName]["enabled"]
    print "\n#{@ncl}Database ......... #{@gre}"
    print @apps[appName]["db"]
    print "\n#{@ncl}Online ........... #{@gre}"
    print @apps[appName]["online"]
    print "#{@ncl}\n\n"

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Check database information and create it if needed
  #
  def deployDatabase(appName)

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Check DB information on application:

    dbConfigFile = "#{@productionFolder}#{appName}#{@databaseYml}"

    @put.normal "Checking DB file: #{dbConfigFile}"

    unless File.exists?(dbConfigFile)
      @put.error "Database file does not exist"
      exit
    end

    dbDetails = YAML.load_file(dbConfigFile)

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Load information:

    productionDB = dbDetails['production']
    # @put.static "Production DB details:"
    # puts productionDB

    if productionDB.nil?
      @put.green "Nothing to do with the database"
      return
    end

    dbAdapter = productionDB['adapter']

    # If this is a SQLite 3, accept it:

    if dbAdapter == "sqlite3"
      @put.green "Sqlite3 detected!"
      @apps[appName]["db"] = true
      saveData
      return
    end

    # If PostgreSQL, go on:

    dbName = productionDB['database']
    dbUser = productionDB['username']
    dbPass = productionDB['password']

    if dbPass.nil?
      @put.error "No password, ignoring database"
      exit
    end

    # @put.normal "Name: #{dbName}"
    # @put.normal "User: #{dbUser}"
    # @put.normal "Pass: #{dbPass}"

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Checking user:

    @put.normal "Checking DB user existence"
    userExistent = checkDbUser(dbUser)
    @put.confirm

    if userExistent
      @put.green "User registered."
    else
      @put.green "No user defined."
      @put.normal "Creating new user '#{dbUser}'"

      newUser = createDbUser(dbUser, dbPass)

      unless newUser
        @put.error "Unable to create DB user"
        exit
      else
        userExistent = true
        @put.confirm
      end
    end

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Checking database:

    @put.normal "Checking database existence"
    dbExistent = checkDb(dbName)

    if dbExistent
      @put.confirm
    else
      @put.green "No database defined."
      @put.normal "Creating new database"

      newDB = createProductionDb(dbUser, dbName)

      if newDB
        dbExistent = true
        @put.confirm
      else
        @put.error "Unable to create database"
        exit
      end
    end

    if userExistent && dbExistent
      @apps[appName]["db"] = true
      saveData
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deploy application
  #
  def deploy(appName, skipBundle=false, skipAssets=false)

    @put.green "[Checking data]"

    if @apps[appName]["repository"]
      if @apps[appName]["thin"]
        if @apps[appName]["available"]
          @put.green "All seems to be fine, yay!"
        else
          @put.error "Nginx configuration not saved"
          return
        end
      else
        @put.error "Thin configuration not saved"
        return
      end
    else
      @put.error "Repository non-existent"
      return
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    puts @apps[appName]

    # If already online, stop thin.

    if @apps[appName]["online"]
      stopApp(appName)
    end

    # Deploy database

    @put.normal "Checking database"

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Check data:

    if @apps[appName]["db"] == false
      @put.green "No database on record."
      deployDatabase appName
    else
      @put.confirm
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    @put.green "[Deploying]"
    Dir.chdir "#{@productionFolder}#{appName}"

    unless skipBundle

      @put.normal "Executing 'bundle package'"
      action = @system.execute("bundle package")

      if action.success?
        @put.confirm
      else
        @put.error "Could not bundle package"
        exit
      end

      @put.normal "Executing 'bundle install'"
      action = @system.execute("bundle install --deployment")

      if action.success?
        @put.confirm
      else
        @put.error "Could not bundle install"
        exit
      end

    end

    # Check for migrations!

    migrationsFolder = "#{@productionFolder}#{appName}/db/migrate/"
    migrationsNumber = Dir.glob(File.join(migrationsFolder, '**', '*.rb')).count

    if migrationsNumber > 0
      @put.normal "#{migrationsNumber} migrations found."
      @put.normal "Migrating"

      deployStep4 = @system.execute("RAILS_ENV=production rake db:migrate")
      
      if deployStep4.success?
        @put.confirm
      else
        @put.error "Could not migrate database"
        exit
      end

    end

    unless skipAssets

      @put.normal "Precompile assets"
      deployStep5 = @system.execute("rake assets:precompile")

      if deployStep5.success?
        @put.confirm
      else
        @put.error "Could not precompile assets"
        exit
      end

    end

    # If all is fine, start thin, restart nginx.

    startApp(appName)

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

    @nginx.stop
    resetApplicationData
    @apps.each {|key, value|
        reset(key)
    }
    @nginx.start

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Sets new value in the apps hash
  #
  def setParameters(appName, newValues)

    puts "appname = #{appName}"
    puts "newValues = #{newValues}"

    unless @apps.has_key?(appName)
      @put.error "There is no application with the name '#{appName}'"
      exit
    end

    # newValues = "url:www.me.com,ports:3"
    newHash = newValues.split(',').inject(Hash.new{|h,k|h[k]=[]}) do |h, s|
      k,v = s.split(':')
      h[k] = v.to_i == 0 ? v : v.to_i
      h
    end

    # puts newHash
    @put.normal "Setting new values"

    resetPorts = false

    newHash.each {|key, value|
      # @put.green "#{key} = #{value}"
      @apps[appName][key] = value
      if key == "ports"
        resetPorts = true
      end
    }

    # @apps[appName][key] = value
    saveData

    @put.confirm

    if resetPorts
      resetApplicationData
      @put.normal "Warning: double-check the applications' ports and thin files."
    end
    # resetAll

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes configuration files and stops the application
  #
  def disable(appName)
    @nginx.stop
    stopThin(appName)
    deleteNginxConfigFile(appName)
    deleteThinConfigFile(appName)
    @nginx.start
    @apps[appName]["online"] = false
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def destroydb
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def destroy(appName)
    disable appName
    action = @system.execute( "rm -rf #{@productionFolder}#{appName} && sudo -u git rm -rf #{@repositoriesFolder}#{appName}.git" )

    if action.success?
      @apps.delete(appName)
      saveData
      @put.green "#{appName.capitalize} destroyed!"
    else
      @put.error "Problem trying to destroy #{appName}."
    end
  end

  #

  # def resethard
  #   system( "rm -rf #{@productionFolder}*" )
  #   system( "rm -rf #{@productionFolder}*" )
  # end

end
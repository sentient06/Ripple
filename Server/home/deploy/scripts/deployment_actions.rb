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

    @server               = generalData['serverName']
    @deployerUser         = generalData['deployerUser']
    @gitUser              = generalData['gitUser']
    @dataFile             = generalData['dataFile']
    @repositoriesFolder   = generalData['repositoriesFolder']
    @templatesFolder      = generalData['templatesFolder']
    @productionFolder     = generalData['productionFolder']
    @databaseYml          = generalData['databaseYml']
    @nginxAvailableFolder = generalData['nginxAvailableFolder']
    @nginxEnabledFolder   = generalData['nginxEnabledFolder']

    @rubyPath             = ENV["MY_RUBY_HOME"] + "/bin/ruby"
    @rvmPath              = ENV["rvm_path"] + "/bin/rvm"
    @thinPath             = ENV["rvm_path"] + "/gems/" + ENV["RUBY_VERSION"] + "@4.1.2/bin/thin"
    @bundlePath           = ENV["rvm_path"] + "/gems/" + ENV["RUBY_VERSION"] + "@global/bin/bundle"
    @rakePath             = ENV["rvm_path"] + "/rubies/" + ENV["RUBY_VERSION"] + "/bin/rake"

    # print "@deployerUser         ->  #{@deployerUser}\n"
    # print "@gitUser              ->  #{@gitUser}\n"
    # print "@dataFile             ->  #{@dataFile}\n"
    # print "@repositoriesFolder   ->  #{@repositoriesFolder}\n"
    # print "@templatesFolder      ->  #{@templatesFolder}\n"
    # print "@productionFolder     ->  #{@productionFolder}\n"
    # print "@databaseYml          ->  #{@databaseYml}\n"
    # print "@nginxAvailableFolder ->  #{@nginxAvailableFolder}\n"
    # print "@nginxEnabledFolder   ->  #{@nginxEnabledFolder}\n"
    # print "@rubyPath             ->  #{@rubyPath}\n"

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    @system   = System.new
    @put      = Put.new
    @nginx    = Nginx.new(@templatesFolder, @nginxAvailableFolder, @nginxEnabledFolder)
    @thin     = Thin.new
    @git      = Git.new(@rubyPath, @gitUser, @repositoriesFolder, @productionFolder)
    @database = Database.new

    loadData

  end

  #-------------------------------------------------------------------------------
  # Getters to use on IRB

  def vars
    puts "dataFile\nrepositoriesFolder\ntemplatesFolder\nproductionFolder\ndatabaseYml\nlastMsg\napps"
  end

  attr_reader :dataFile, :repositoriesFolder, :templatesFolder, :productionFolder, :databaseYml, :lastMsg, :apps, :rubyPath

  #-------------------------------------------------------------------------------
  # Data methods

  def loadData
    unless File.exists?(@dataFile)
      @apps = Hash.new
      @put.static "List of apps unavailable."
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
  # Lists all applications names, ports used and url.
  #
  def list
    if @apps.count < 1
      @put.static "No applications found.\n"
      exit
    end
    # Iterate through all apps and print
    len    = 15
    bigKey = @apps.keys.max { |a, b| a.length <=> b.length }
    len    = bigKey.length
    print "\nList of applications\n--------------------\n"
    @apps.each {|key, value|
      printf("#{@ncl} [#{@gre}%-#{len}s#{@ncl}] - #{@gre}%02d#{@ncl}p | #{@gre}%4d#{@ncl} | #{@pur}%s%s%s%s%s%s%s#{@ncl} | #{@gre}%s#{@ncl}\n",
          key.to_s,
          value['ports'].count,
          value['ports'][0],
          value["repository"] ? "R" : "-",
          value["thin"]       ? "T" : "-",
          value["available"]  ? "A" : "-",
          value["enabled"]    ? "E" : "-",
          value["db"]         ? "D" : "-",
          value["online"]     ? "O" : "-",
          value["update"]     ? "U" : "-",
          value['url']
        )
    }
    print "\n"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates a new application
  #
  def addApplication(appName, appURL, appPorts)  
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
    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    print "\n#{@cya}Creating application '#{appName}'\n"
    puts "-" * (appName.length + 21)
    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Create empty application:
    @apps[appName]               = Hash.new
    @apps[appName]["name"]       = appName
    @apps[appName]["url"]        = appURL # application dns - Test with an array
    @apps[appName]["ports"]      = []     # thin ports
    @apps[appName]["repository"] = false  # repository created
    @apps[appName]["thin"]       = false  # thin configuration
    @apps[appName]["available"]  = false  # nginx available config
    @apps[appName]["enabled"]    = false  # nginx enabled config
    @apps[appName]["db"]         = false  # existing database
    @apps[appName]["online"]     = false  # online
    @apps[appName]["update"]     = true   # must update thin and nginx files
    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Set git repository for deployment:
    appPorts.to_i.times { @apps[appName]["ports"].push(0) }
    setNewApplicationsPorts

    success = @git.createRepository(appName)
    unless success == 1
      @apps[appName]["repository"] = true
      saveData
    else
      exit
    end
    success = @git.cloneRepository(appName)
    if success == 1
      exit
    end
    @put.green "Your application's repository is ready."
    @put.green "Please add the remote address:"
    @put.static "git remote add #{@server} git@#{@server}:repositories/#{appName}.git"
    print "\n"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Resets ports setup for all applications
  #
  def setNewApplicationsPorts
    firstPort = 3000
    currentPort = firstPort
    # Iterate apps and store used ports
    @apps.each {|key, anApp|
      originalSetup = anApp['ports']
      totalPorts    = anApp['ports'].count
      @apps[key]['ports'] = []
      totalPorts.times do |i|
        @apps[key]['ports'].push(currentPort)
        currentPort += 1
      end
      unless @apps[key]['ports'] == originalSetup
        @apps[key]['update'] = true
      end
    }
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deploy application
  #
  def deploy(appName, skipBundle=false, skipAssets=false)

    @put.green "[Deployment]"

    if @apps[appName]["update"]
      updateConfigs
      exit
    end

    appStatus appName

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
    # If already online, stop thin.

    if @apps[appName]["online"]
      stopApp(appName)
    end

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
    # Deploy database

    @put.normal "Checking database"

    if @apps[appName]["db"] == false
      @put.green "No database on record."
      deployDatabase(appName)
    else
      @put.confirm
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Bundle actions

    unless skipBundle
      appPath = "#{@productionFolder}#{appName}"

      @put.normal "Executing 'bundle package'"
      action = @system.execute("#{@bundlePath} package", appPath, true)

      if action.success?
        @put.confirm
      else
        @put.error "Could not bundle package"
        exit
      end

      @put.normal "Executing 'bundle install'"
      action = @system.execute("#{@bundlePath} install --deployment", appPath)

      if action.success?
        @put.confirm
      else
        @put.error "Could not bundle install"
        exit
      end
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Migrations

    if @apps[appName]["db"] == true
      migrationsFolder = "#{@productionFolder}#{appName}/db/migrate/"
      migrationsNumber = Dir.glob(File.join(migrationsFolder, '**', '*.rb')).count
      if migrationsNumber > 0
        @put.normal "#{migrationsNumber} migrations found."
        @put.normal "Migrating"
        migrations = @system.execute("RAILS_ENV=production rake db:migrate")
        if migrations.success?
          @put.confirm
        else
          @put.error "Could not migrate database"
          exit
        end
      else
        @put.green "No migrations found."
      end
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Assets

    unless skipAssets
      @put.normal "Precompiling assets"
      precompile = @system.execute("#{@rakePath} assets:precompile", "", true)
      if precompile.success?
        @put.confirm
      else
        @put.error "Could not precompile assets"
        exit
      end
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Nginx enable

    success = @nginx.enableConfigFile(appName)
    unless success == 1
      @apps[appName]["enabled"] = true
      saveData
    else
      exit
    end

    # If all is fine, start thin, restart nginx.
    startApp(appName)

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Starts application
  #
  def startApp(appName)
    @nginx.stop
    @thin.start(appName)
    @nginx.start
    @apps[appName]["online"] = true
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Stops application
  #
  def stopApp(appName)
    @nginx.stop
    @thin.stop(appName)
    @nginx.start
    @apps[appName]["online"] = false
    saveData
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
    userExistent = @database.findUser(dbUser)
    @put.confirm

    if userExistent
      @put.green "User registered."
    else
      @put.green "No user defined."
      @put.normal "Creating new user '#{dbUser}'"

      newUser = @database.addUser(dbUser, dbPass)

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
    dbExists = @database.findDb(dbName)

    if dbExists
      @put.confirm
    else
      @put.green "No database defined."
      @put.normal "Creating new database"
      newDB = @database.addDb(dbUser, dbName)
      if newDB
        dbExists = true
        @put.confirm
      else
        @put.error "Unable to create database"
        exit
      end
    end

    if userExistent && dbExists
      @apps[appName]["db"] = true
      saveData
    end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
  # Prints details about a given application.
  #
  def appStatus(appName)
    print "\n#{@gre}#{appName.capitalize} application's details\n"
    puts '-' * (appName.length + 22)
    print "\n#{@ncl}URL .............. #{@gre}"
    print @apps[appName]["url"]
    print "\n#{@ncl}Ports ............ #{@gre}"
    print @apps[appName]["ports"]
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
    print "\n#{@ncl}Update ........... #{@gre}"
    print @apps[appName]["update"]
    print "#{@ncl}\n\n"
  end

  #---------------------------------------------------------------------------
  # Action methods

  def test
    print "\n"
    print "#{@cya}Printing global variables#{@ncl}\n"
    print "#{@cya}-------------------------#{@ncl}\n"
    print "#{@cya}Server               = #{@gre}#{@server}#{@ncl}\n"
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

    print "ruby -v .............. "
    system("#{@rubyPath} -v")

    print "thin -v .............. "
    system("#{@thinPath} -v")

    print "bundle -v ............ "
    system("#{@bundlePath} -v")

    print "\n"
  end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # # Updates both Nginx and Thin config files for any outdated applications.
  # #
  # def updateConfigs
  #   @put.green "Updating applications"
  #   toUpdate = @apps.select{|appName, keys|
  #     keys['update'] == true
  #   }
  #   if toUpdate.count > 0
  #     @put.normal "Stopping applications"
  #     @nginx.stop
  #   end
  #   toUpdate.each { |appName, keys|
  #     if @apps[appName]["thin"] == true
  #       @thin.stop(appName)
  #     end
  #   }
  #   if @nginx.still
  #     @put.confirm
  #   end
  #   toUpdate.each { |appName, keys|
  #     # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
  #     # Save server configurations:
  #     success = @nginx.availConfigFile(@apps[appName])
  #     unless success == 1
  #       @apps[appName]["available"] = true
  #     else
  #       exit
  #     end
  #     @thin.saveConfigFile(@apps[appName])   # thin
  #     unless success == 1
  #       @apps[appName]["thin"] = true
  #     else
  #       exit
  #     end
  #     @apps[appName]["update"] = false
  #   }
  #   if @nginx.still
  #     @nginx.start
  #   end
  #   saveData
  # end



  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # def setApplicationPorts(appName, appPorts)
  #   firstPort               = 3000
  #   @apps[appName]['ports'] = []
  #   usedPorts               = []
  #   newPorts                = []
  #   # Iterate apps and store used ports
  #   @apps.each {|key, anApp|
  #     anApp['ports'].each {|port|
  #       usedPorts.push(port)
  #     }
  #   }
  #   # Last port used
  #   lastPort = usedPorts.none? ? firstPort : usedPorts.max
  #   # New ports in range
  #   (firstPort..lastPort).each {|v|
  #     unless usedPorts.include? v
  #       newPorts.push(v)
  #     end
  #   }
  #   # New ports out of range
  #   if newPorts.count < appPorts
  #     remainingPorts = ports-newPorts.count
  #     (lastPort+1..lastPort+remainingPorts).each {|v|
  #         newPorts.push(v)
  #     }    
  #   end
  #   @apps[appName]['ports'] = newPorts
  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # def resetApplicationData

  #   port = 3000

  #   @put.normal "Setting ports"
  #   thinConfigChange = Array.new
  #   nginxConfigChange = Array.new

  #   # Iterates through all apps to store correct ports:
  #   @apps.each {|key, value|
  #     value["ports"].times do |i|
  #       print "\r"
  #       if i == 0
          
  #         if value["first"] != port
  #           value["first"] = port
  #           if value["thin"] == true
  #             thinConfigChange.push(value['name'])
  #           end
  #           if value["available"] == true
  #             nginxConfigChange.push(value['name'])
  #           end
  #         end

  #       end
  #       # puts "#{@gre} - Port #{port} - #{key}#{@ncl}"
  #       port += 1
  #     end
  #   }

  #   @put.confirm
  #   saveData

  #   return

  #   # to test:

  #   if thinConfigChange.length > 0
  #     thinConfigChange.each { |app|
  #       @thin.saveConfigFile(@apps[app])
  #     }
  #   end

  #   if nginxConfigChange.length > 0
  #     nginxConfigChange.each { |app|
  #       @nginx.availConfigFile(@apps[app])
  #     }
  #   end

  # end

  # #---------------------------------------------------------------------------
  # # Secondary methods



  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # def disableNginxConfigFile(appName)

  #   nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
  #   nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"

  #   if File.exists?(nginxConfigLink)
  #     @put.normal "Deleting symlink for #{appName}"
  #     nginxCmd1 = @system.execute("rm #{nginxConfigLink}")

  #     if nginxCmd1.success?
  #       @apps[appName]["enabled"] = false
  #       @put.confirm
  #       saveData
  #     else
  #       @put.error "Could not delete configuration symlink for #{appName}"
  #     end

  #   else
  #     @put.green "No symlink found."
  #   end

  # end

  # def deleteNginxConfigFile(appName) #hinder?

  #   disableNginxConfigFile(appName)

  #   nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"

  #   if File.exists?(nginxConfigFile)

  #     @put.normal "Deleting Nginx configuration for #{appName}"
  #     nginxCmd2 = @system.execute("rm #{nginxConfigFile}")

  #     if nginxCmd2.success?
  #       @apps[appName]["available"] = false
  #       saveData
  #       @put.confirm
  #     else
  #       @put.error "Could not delete configuration file for #{appName}"
  #       return
  #     end

  #   else
  #     @put.green "No config file found."
  #   end

  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # def deleteThinConfigFile(appName)

  #   @put.normal "Deleting Thin configuration for #{appName}"
  #   thinCmd = @system.execute("rm /etc/thin/#{appName}.yml")

  #   if thinCmd.success?
  #     @put.confirm
  #   else
  #     @put.error "Could not delete Thin configuration for #{appName}"
  #     return
  #   end

  #   @apps[appName]["thin"] = false
  #   saveData

  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # def startNginx
  #   @nginx.start
  # end

  # def stopNginx
  #   @nginx.stop
  # end

  # # Relocating to Thin class

  # def startThin(appName)
  #   # @put.normal "Starting thin for #{appName}"
  #   # command = @system.execute( "thin start -C /etc/thin/#{appName}.yml" )
  #   # if command.success?
  #   #   @put.confirm
  #   # else
  #   #   @put.error "Could not start Thin"
  #   #   exit
  #   # end
  #   @thin.start(appName)
  # end

  # # Relocating to Thin class

  # def stopThin(appName)
  #   # @put.normal "Stopping thin for #{appName}"
  #   # command = @system.execute( "thin stop -C /etc/thin/#{appName}.yml" )
  #   # if command.success?
  #   #   @put.confirm
  #   # else
  #   #   @put.error "Could not stop Thin"
  #   #   exit
  #   # end
  #   @thin.stop(appName)
  # end





  # def resetServers
  #   @put.normal "Restarting servers"
  #   stopServers
  #   startServers
  # end

  # def stopServers

  #   @nginx.stop
  #   @put.normal "Stopping Thin"

  #   # Iterates through all apps to stop server instances:

  #   @apps.each {|key, value|
  #     if value["online"]
  #       command = @system.execute("thin stop -C /etc/thin/#{key}.yml")
  #     end
  #   }

  # end

  # def startServers

  #   @put.normal "Starting servers"
  #   @put.normal "Starting Thin"

  #   @apps.each {|key, value|
  #     if value["online"]
  #       command = @system.execute( "thin start -C /etc/thin/#{key}.yml" )
  #     end
  #   }

  #   @nginx.start

  # end









  

  

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # # Rewrites the config files and resets thin
  # #
  # def reset(appName)

  #   if @apps[appName]["online"]
  #     stopThin(appName)
  #   end

  #   deleteNginxConfigFile(appName)
  #   deleteThinConfigFile(appName)
  #   @thin.saveConfigFile(@apps[appName])
  #   @nginx.availConfigFile(@apps[appName])
  #   enableNginxConfigFile

  #   if @apps[appName]["online"]
  #     startThin(appName)
  #   end

  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # # Rewrites the config files and resets the servers
  # #
  # def resetAll

  #   @nginx.stop
  #   resetApplicationData
  #   @apps.each {|key, value|
  #       reset(key)
  #   }
  #   @nginx.start

  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # # Sets new value in the apps hash
  # #
  # def setParameters(appName, newValues)

  #   puts "appname = #{appName}"
  #   puts "newValues = #{newValues}"

  #   unless @apps.has_key?(appName)
  #     @put.error "There is no application with the name '#{appName}'"
  #     exit
  #   end

  #   # newValues = "url:www.me.com,ports:3"
  #   newHash = newValues.split(',').inject(Hash.new{|h,k|h[k]=[]}) do |h, s|
  #     k,v = s.split(':')
  #     h[k] = v.to_i == 0 ? v : v.to_i
  #     h
  #   end

  #   # puts newHash
  #   @put.normal "Setting new values"

  #   resetPorts = false

  #   newHash.each {|key, value|
  #     # @put.green "#{key} = #{value}"
  #     @apps[appName][key] = value
  #     if key == "ports"
  #       resetPorts = true
  #     end
  #   }

  #   # @apps[appName][key] = value
  #   saveData

  #   @put.confirm

  #   if resetPorts
  #     resetApplicationData
  #     @put.normal "Warning: double-check the applications' ports and thin files."
  #   end
  #   # resetAll

  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # # Deletes configuration files and stops the application
  # #
  # def disable(appName)
  #   @nginx.stop
  #   stopThin(appName)
  #   deleteNginxConfigFile(appName)
  #   deleteThinConfigFile(appName)
  #   @nginx.start
  #   @apps[appName]["online"] = false
  #   saveData
  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # def destroydb
  # end

  # #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # def destroy(appName)
  #   disable appName
  #   action = @system.execute( "rm -rf #{@productionFolder}#{appName} && sudo -u git rm -rf #{@repositoriesFolder}#{appName}.git" )

  #   if action.success?
  #     @apps.delete(appName)
  #     saveData
  #     @put.green "#{appName.capitalize} destroyed!"
  #   else
  #     @put.error "Problem trying to destroy #{appName}."
  #   end
  # end

  # #

  # # def resethard
  # #   system( "rm -rf #{@productionFolder}*" )
  # #   system( "rm -rf #{@productionFolder}*" )
  # # end

end
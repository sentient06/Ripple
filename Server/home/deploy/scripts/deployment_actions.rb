# deployment_actions.rb
# Ripple
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

# @apps[appName]["name"]       # application name
# @apps[appName]["directory"]  # application dir
# @apps[appName]["url"]        # application dns
# @apps[appName]["ports"]      # quantity of thin ports
# @apps[appName]["repository"] # repository created
# @apps[appName]["thin"]       # thin configuration
# @apps[appName]["available"]  # nginx available config
# @apps[appName]["enabled"]    # nginx enabled config
# @apps[appName]["db"]         # existing database
# @apps[appName]["dbname"]     # database name
# @apps[appName]["adapter"]    # database adapter
# @apps[appName]["backup"]     # database last backup date
# @apps[appName]["online"]     # servers on
# @apps[appName]["update"]     # must update thin and nginx files

require 'erb'
require 'yaml'
require 'date'

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

    @rubyPath             = "/usr/bin/ruby" # Dropped on v 2.2? ENV["MY_RUBY_HOME"] + "/bin/ruby"
    @rvmPath              = ENV["rvm_path"] + "/bin/rvm"
    @thinPath             = ENV["rvm_path"] + "/gems/ruby-" + RUBY_VERSION + "@4.2.0/bin/thin"
    @bundlePath           = ENV["rvm_path"] + "/gems/" + RUBY_VERSION + "@global/bin/bundle"
    @rakePath             = ENV["rvm_path"] + "/rubies/" + RUBY_VERSION + "/bin/rake"

    # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

    @system   = System.new
    @files    = Files.new(@productionFolder)
    @put      = Put.new
    @nginx    = Nginx.new(@templatesFolder, @nginxAvailableFolder, @nginxEnabledFolder)
    @thin     = Thin.new
    @git      = Git.new(@rubyPath, @gitUser, @repositoriesFolder, @productionFolder)
    @database = Database.new(@productionFolder)

    loadData

  end

  #-------------------------------------------------------------------------------
  # Getters to use on IRB

  def vars
    puts "dataFile\nrepositoriesFolder\ntemplatesFolder\nproductionFolder\ndatabaseYml\nlastMsg\napps"
  end

  attr_reader :dataFile, :repositoriesFolder, :templatesFolder, :productionFolder, :databaseYml, :lastMsg, :apps, :rubyPath

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Loads application data
  #
  def loadData
    unless File.exists?(@dataFile)
      @apps = Hash.new
      @put.feedback "List of apps unavailable."
    else
      @apps = Marshal.load File.read(@dataFile)
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Saves application data
  #
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
      @put.feedback "No applications found.\n"
      exit
    end
    # Iterate through all apps and print
    len    = 15
    bigKey = @apps.keys.max { |a, b| a.length <=> b.length }
    len    = bigKey.length
    print "\nList of applications\n--------------------\n"
    @apps.each {|key, value|
      printf("#{@ncl} [#{@gre}%-#{len}s#{@ncl}] - #{@gre}%02d#{@ncl}p | #{@gre}%4d#{@ncl} | DB: #{@gre}%s#{@ncl} | #{@pur}%s%s%s%s%s%s%s#{@ncl} | #{@gre}%s#{@ncl}\n",
          key.to_s,
          value['ports'].count,
          value['ports'][0],
          value['adapter'] == "sqlite3"    ? "S3" :
          value['adapter'] == "postgresql" ? "PG" : "--",
          value["repository"] ? "R" : "-",
          value["thin"]       ? "T" : "-",
          value["available"]  ? "A" : "-",
          value["enabled"]    ? "E" : "-",
          value["db"]         ? "D" : "-",
          value["online"]     ? "O" : "-",
         !value["update"]     ? "U" : "-",
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
    @apps[appName]["directory"]  = appName
    @apps[appName]["url"]        = appURL # application dns - Test with an array
    @apps[appName]["ports"]      = []     # thin ports
    @apps[appName]["repository"] = false  # repository created
    @apps[appName]["thin"]       = false  # thin configuration
    @apps[appName]["available"]  = false  # nginx available config
    @apps[appName]["enabled"]    = false  # nginx enabled config
    @apps[appName]["db"]         = false  # existing database
    @apps[appName]["dbname"]     = nil    # database name
    @apps[appName]["adapter"]    = nil    # database adapter
    @apps[appName]["backup"]     = nil    # database last backup date
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
    showGitRemote(appName)
    print "\n"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Echoes the git remote line
  #
  def showGitRemote(appName)
    @put.green "Please add the remote address:"
    @put.static "git remote add #{@server} git@#{@server}:repositories/#{appName}.git"
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

    # Update
    if @apps[appName]["update"]
      updateConfigs
      exit
    end

    # Status
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
    # If already online, stop thin and disable Nginx for this app

    if @apps[appName]["online"]
      @nginx.stop
      @thin.stop(appName)
      @apps[appName]["online"] = false
      if @apps[appName]['enabled']
        @nginx.disableConfigFile(appName)
        @apps[appName]['enabled'] = false
      end
      saveData
      @nginx.start
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
        @put.static "#{migrationsNumber} migrations found."
        @put.normal "Migrating"
        # def execute(command, inPath = "", showOutput = false, user = "")
        migrations = @system.execute("RAILS_ENV=production #{@rakePath} db:migrate", "", true)
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
    # If all is fine, start thin and nginx.

    unless @files.findGemForApp('thin', appName)
      @put.error "Thin is missing from the Gemfile"
      exit
    end

    @nginx.stop

    success = @nginx.enableConfigFile(appName)
    unless success == 1
      @apps[appName]["enabled"] = true
      saveData
    else
      exit
    end

    success = @thin.start(appName)
    unless success == 1
      @apps[appName]["online"] = true
      saveData
    else
      exit
    end

    @nginx.start

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Starts application
  #
  def startApplication(appName, skipNginx = false)
    if @apps[appName]["online"]
      @put.feedback "Application is already running"
      return
    end
    unless @apps[appName]['enabled']
      @put.feedback "Please execute 'enable' command"
      return
    end
    unless skipNginx
      @nginx.stop
    end
    success = @thin.start(appName)
    unless success == 1
      @apps[appName]["enabled"] = true
      saveData
    else
      exit
    end
    unless skipNginx
      success = @nginx.start
      unless success == 1
        @apps[appName]["online"] = true
        saveData
      else
        exit
      end
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Enables application
  #
  def enable(appName)
    if @apps[appName]['enabled']
      @put.feedback "Application is already enabled"
      return
    end
    unless @apps[appName]['available']
      @put.feedback "Please execute 'avail' command"
      return
    end
    @nginx.stop
    @nginx.enableConfigFile(appName)
    @apps[appName]['enabled'] = true
    saveData
    @nginx.start
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates Thin and Nginx config files
  #
  def avail(appName)
    if @apps[appName]['available']
      @put.feedback "Application is already available"
      return
    end
    @nginx.availConfigFile(@apps[appName])
    @thin.saveConfigFile(@apps[appName])
    @apps[appName]["available"] = true
    @apps[appName]["thin"] = true
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Stops application. Used by user.
  #
  def stopApplication(appName, skipNginx = false)
    unless @apps[appName]["online"]
      @put.feedback "Application is already still"
      return
    end
    unless skipNginx
      @nginx.stop
    end
    @thin.stop(appName)
    unless skipNginx
      @nginx.start
    end
    @apps[appName]["online"] = false
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Disables application
  #
  def disable(appName)
    unless @apps[appName]['enabled']
      @put.feedback "Application is already disabled"
      return
    end
    if @apps[appName]['online']
      @put.feedback "Please execute 'stop' command"
      return
    end
    @nginx.stop
    @nginx.disableConfigFile(appName)
    @apps[appName]['enabled'] = false
    saveData
    @nginx.start
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes Thin and Nginx config files
  #
  def hinder(appName)
    unless @apps[appName]['available']
      @put.feedback "Application is already unavailable"
      return
    end
    if @apps[appName]['enabled']
      @put.feedback "Please execute 'disable' command"
      return
    end
    @nginx.deleteConfigFile(appName)
    @thin.deleteConfigFile(appName)
    @apps[appName]["available"] = false
    @apps[appName]["thin"] = false
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Destroys application's repository and www directory
  #
  def destroy(appName)
    unless @apps.has_key?(appName)
      @put.error "There is no application with the name '#{appName}'"
      return
    end
    if @apps[appName]['available']
      @put.feedback "Please execute 'hinder' command"
      return
    end
    @put.red "Destroying application '#{appName}'"
    dir = "#{@productionFolder}#{appName}"
    @put.normal "Removing #{dir}"
    command = @system.deleteDir(dir)
    unless command.success?
      @put.error "Could not remove dir at path '#{dir}'"
      @put.red @system.output
      exit
    else
      @put.confirm
    end
    dir = "#{@repositoriesFolder}#{appName}.git"
    @put.normal "Removing #{dir}"
    command = @git.deleteRepositoryDirectory(appName)
    unless command.success?
      @put.error "Could not remove dir at path '#{dir}'"
      @put.red @system.output
      exit
    else
      @put.confirm
    end
    @apps.delete(appName)
    saveData
    @put.red "Destroyed!"
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
    @put.confirm

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
    @apps[appName]["adapter"] = dbAdapter

    # If this is a SQLite 3, accept it:
    if dbAdapter == "sqlite3"
      @put.green "Sqlite3 detected!"
      if @files.findGemForApp('sqlite3', appName)
        @apps[appName]["db"] = true
      else
        @put.error "SQLite (sqlite3) is missing from the Gemfile"
        exit
      end
      saveData
      return
    end

    if @files.findGemForApp('pg', appName)
      @apps[appName]["db"] = true
    else
      @put.error "Postgres (pg) is missing from the Gemfile"
      exit
    end
    saveData

    # If PostgreSQL, go on:
    dbName = productionDB['database']
    dbUser = productionDB['username']
    dbPass = productionDB['password']

    @apps[appName]["dbname"] = dbName

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
    userExistent = @database.findUserPG(dbUser)
    @put.confirm

    if userExistent
      @put.green "User registered."
    else
      @put.green "No user defined."
      @put.yellow "Creating new user '#{dbUser}'"

      newUser = @database.addUserPG(dbUser, dbPass)

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
    dbExists = @database.findPG(dbName)

    if dbExists
      @put.confirm
    else
      @put.green "No database defined."
      @put.normal "Creating new database"
      newDB = @database.addPG(dbUser, dbName)
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

    if @apps[appName].nil?
      @put.error "There is no application with that name"
      return
    end    

    print "\n#{@gre}#{appName.capitalize} application's details\n"
    puts '-' * (appName.length + 22)

    print "\n#{@ncl}URL .............. "
    print @cya
    print @apps[appName]["url"]

    print "\n#{@ncl}Ports ............ "
    print @cya
    print @apps[appName]["ports"]

    print "\n#{@ncl}Repository ....... "
    print (@apps[appName]["repository"] ? @gre : @red)
    print  @apps[appName]["repository"]

    print "\n#{@ncl}Thin config ...... "
    print (@apps[appName]["thin"] ? @gre : @red)
    print  @apps[appName]["thin"]

    print "\n#{@ncl}Nginx available .. "
    print (@apps[appName]["available"] ? @gre : @red)
    print  @apps[appName]["available"]

    print "\n#{@ncl}Nginx enabled .... "
    print (@apps[appName]["enabled"] ? @gre : @red)
    print  @apps[appName]["enabled"]

    print "\n#{@ncl}Database ......... "
    print (@apps[appName]["db"] ? @gre : @red)
    print  @apps[appName]["db"]

    print "\n#{@ncl}Adapter .......... "
    if @apps[appName]["adapter"].nil?
      print "#{@red}none"
    else
      print @gre
      print @apps[appName]["adapter"]
    end

    print "\n#{@ncl}DB backup ........ "
    if @apps[appName]["backup"].nil?
      print "#{@red}none"
    else
      print @gre
      print @apps[appName]["backup"].strftime("%d/%m/%Y")
    end

    print "\n#{@ncl}Online ........... "
    print (@apps[appName]["online"] ? @gre : @red)
    print  @apps[appName]["online"]

    print "\n#{@ncl}Updated .......... "
    print (@apps[appName]["update"] ? @red : @gre) 
    print !@apps[appName]["update"]

    if @apps[appName]["directory"] != @apps[appName]["name"]
      print "\n#{@ncl}Directory ........ "
      print @yel
      print @apps[appName]["directory"]
    end

    print "#{@ncl}\n\n"
  end

  #---------------------------------------------------------------------------
  # Action methods

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Prints some stuff and tests some server stuff
  #
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
   
    print "whoami .................. "
    system("whoami")

    print "sudo -u git whoami ...... "
    system("sudo -u git whoami")

    print "sudo -u postgres whoami . "
    system("sudo -u postgres whoami")

    print "ruby -v ................. "
    system("#{@rubyPath} -v")

    # print "thin -v ................. " # y u not work!?
    # system("#{@thinPath} -v")
    # print "\n"

    print "bundle -v ............... "
    system("#{@bundlePath} -v")

    print "\n"
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Updates both Nginx and Thin config files for any outdated applications.
  #
  def updateConfigs
    @put.green "Updating applications"
    toUpdate = @apps.select{|appName, keys|
      keys['update'] == true
    }
    unless toUpdate.count > 0
      @put.feedback "No applications to be updated"
      return
    else
      @put.normal "Stopping applications"
      @nginx.stop
    end
    toUpdate.each { |appName, keys|
      if @apps[appName]["thin"] == true
        @thin.stop(appName)
      end
    }
    if @nginx.still
      @put.confirm
    end
    toUpdate.each { |appName, keys|
      # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
      # Save server configurations:
      success = @nginx.availConfigFile(@apps[appName])
      unless success == 1
        @apps[appName]["available"] = true
      else
        exit
      end
      @thin.saveConfigFile(@apps[appName])   # thin
      unless success == 1
        @apps[appName]["thin"] = true
      else
        exit
      end
      @apps[appName]["update"] = false
    }
    if @nginx.still
      @nginx.start
    end
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Sets new value in the apps hash
  #
  def set(appName, newValues)

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
      if @apps[appName][key].nil?
        # @put.green "#{key} unknown"
      else
        # @put.green "#{key} = #{value}"
        @apps[appName][key] = value
        if key == "ports"
          value.to_i.times do |i|
            @apps[key]['ports'].push(0)
          end
        end
      end
    }

    saveData
    @put.confirm
    appStatus(appName)

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Trigger to stop nginx
  #
  def stopNginx
    @put.feedback "All enabled applications will be offline!"
    @nginx.stop
    toUpdate = @apps.select{|appName, keys|
      keys['enabled'] == true
    }
    toUpdate.each { |appName, keys|
      @apps[appName]["online"] = false
    }
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Trigger to start nginx
  #
  def startNginx
    @put.feedback "All enabled applications will be online!"
    @nginx.start
    toUpdate = @apps.select{|appName, keys|
      keys['enabled'] == true
    }
    toUpdate.each { |appName, keys|
      @apps[appName]["online"] = true
    }
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Restarts all applications
  #
  def restartAll
    @put.feedback "Restarting all"
    @nginx.stop
    stopAll(true)
    startAll(true)
    @nginx.start
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Stops all apps
  #
  def stopAll(skipNginx = false)
    @put.feedback "Stopping all"
    unless skipNginx
      @nginx.stop
    end
    @apps.each {|key, value|
      if value["online"]
        stopApplication(key, true)
      end
    }
    unless skipNginx
      @nginx.start
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Starts all apps
  #
  def startAll(skipNginx = false)
    @put.feedback "Starting all"
    unless skipNginx
      @nginx.stop
    end
    @apps.each {|key, value|
      unless value["online"]
        startApplication(key, true)
        @apps[key]["online"] = true
      end
    }
    unless skipNginx
      @nginx.start
    end
    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates a backup of a database
  #  
  def databaseBackup(appName)
    @put.normal "Creating database backup for #{appName}"
    if @apps[appName]['db']
      if @apps[appName]['adapter'] == "sqlite3"
        success = @database.dumpS3(appName)
      elsif @apps[appName]['adapter'] == "postgresql"
        success = @database.dumpPG(appName, @apps[appName]['dbname'])
      end
      unless success
        @put.error "Could not create backup"
      else
        @apps[appName]['backup'] = DateTime.now
        saveData
        @put.confirm
      end
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Transfers a backup of a database that was uploaded from client
  #  
  def moveBackup(appName)
    @put.normal "Moving database backup file for #{appName}"
    # if @apps[appName]['db']
      success = @database.transferDB(appName)
      unless success
        @put.error "Could not move backup"
      else
        @apps[appName]['backup'] = DateTime.now
        saveData
        @put.confirm
      end
    # end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes PG database
  #  
  def databaseDelete(appName)
    if @apps[appName]['enabled']
      @put.feedback "Please execute 'disable' command"
      return
    end
    # if @apps[appName]['db']
      if @apps[appName]['adapter'] == "sqlite3"
        success = @database.deleteS3(appName)
      elsif @apps[appName]['adapter'] == "postgresql"
        dbConfigFile = "#{@productionFolder}#{appName}#{@databaseYml}"    
        dbDetails = YAML.load_file(dbConfigFile)
        dbUser = dbDetails['production']['username']
        @put.normal "Deleting database for #{appName}"
        success = @database.deletePG(appName, @apps[appName]['dbname'], dbUser)
      end
      if success
        @apps[appName]['db'] = false
        saveData
        @put.confirm
      else
        @put.error "Couldn't delete database"
      end
    # end

  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Restores database
  #  
  def databaseRestore(appName)
    if @apps[appName]['adapter'] == "sqlite3"
      success = @database.restoreS3(appName)
    elsif @apps[appName]['adapter'] == "postgresql"
      @put.normal "Reading DB file"
      dbConfigFile = "#{@productionFolder}#{appName}#{@databaseYml}"    
      dbDetails = YAML.load_file(dbConfigFile)
      dbName = dbDetails['production']['database']
      dbUser = dbDetails['production']['username']
      dbPass = dbDetails['production']['password']
      @put.confirm
      # @put.normal "Adding user"

      # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
      # Checking user:

      @put.normal "Checking DB user existence"
      userExistent = @database.findUserPG(dbUser)
      @put.confirm
      if userExistent
        @put.green "User registered."
      else
        @put.green "No user defined."
        @put.yellow "Creating new user '#{dbUser}'"
        newUser = @database.addUserPG(dbUser, dbPass)
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
      dbExists = @database.findPG(dbName)
      if dbExists
        @put.confirm
      else
        @put.green "No database defined."
        @put.normal "Creating new database"
        newDB = @database.addPG(dbUser, dbName)
        if newDB
          dbExists = true
          @put.confirm
        else
          @put.error "Unable to create database"
          exit
        end
      end
      # if userExistent && dbExists
      #   @apps[appName]["db"] = true
      #   saveData
      # end
    # end





      # if @database.addUserPG(dbUser, dbPass)
        # @put.confirm
        # @put.normal "Adding database"
        # if @database.addPG(dbUser, dbName)
          # @put.confirm
          @put.normal "Restoring database for #{appName}"
          if @database.restorePG(appName, dbName)
            @apps[appName]['db'] = true
            saveData
            @put.confirm
          else
            @put.error "Couldn't restore database"
          end
        # else
          # @put.error "Couldn't add database"
        # end
      # else
        # @put.error "Couldn't add database user"
      # end
    end
  end

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



  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # This is to update server-side information based on new code.
  #
  def masterUpdate
    # Check for app directory entry
    @apps.each {|key, value|
        unless value.has_key?("name")
          @put.cyan "Setting #{key} name"
          @apps[key]["name"] = key
        end
        unless value.has_key?("directory")
          @put.cyan "Setting #{key} directory"
          @apps[key]["directory"] = key
        end
        unless value.has_key?("adapter")
          @put.cyan "Setting #{key} adapter"
          @apps[key]["adapter"] = nil
        end
        unless value.has_key?("dbname")
          @put.cyan "Setting #{key} dbname"
          @apps[key]["dbname"] = nil
        end
    }

    @put.static "Fixing database information"
    @apps.each {|appName, value|
      @put.static "Checking '#{appName}'"
      dbConfigFile = "#{@productionFolder}#{appName}#{@databaseYml}"
      unless File.exists?(dbConfigFile)
        @put.error "Database file does not exist for #{appName}"
        return
      end
      dbDetails = YAML.load_file(dbConfigFile)
      productionDB = dbDetails['production']
      if productionDB.nil?
        @put.green "Nothing to do with the database for #{appName}"
        return
      end
      puts productionDB
      @apps[appName]["adapter"] = productionDB['adapter']
      unless productionDB['adapter'] == "sqlite3"
        @apps[appName]["dbname"] = productionDB['database']
      end
    }

    @apps.each {|appName, value|
      @put.static "Checking '#{appName}'"
      unless value.has_key?("backup")
        @put.cyan "Setting #{appName} backup"
        @apps[appName]["backup"] = nil
      end
    }

    saveData
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # This is to debug
  #
  def masterDebug
    require 'pp'
    generalDataFile = File.join(File.dirname(File.expand_path(__FILE__)), 'general.yml')
    if File.exists?(generalDataFile)
      generalData = YAML.load_file(generalDataFile)
    else
      @put.error "Unable to read general data file."
      exit
    end
    gd = PP.pp(generalData,'',80)
    ap = PP.pp(@apps,'',80)
    @put.cyan "General data"
    puts gd
    @put.cyan "Apps data"
    puts ap
  end

end
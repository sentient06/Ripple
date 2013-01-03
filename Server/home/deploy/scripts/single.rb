# single.rb
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

# Check production password before adding db stuff
# Check if db is needed (look for migrations)
# Always bundle before pushing
# Check if Thin is in the Gemfile



# # App hash:

# @apps[appName]["url"]        # application dns
# @apps[appName]["ports"]      # quantity of thin ports
# @apps[appName]["first"]      # first port, from 3000
# @apps[appName]["installed"]  # dropping it.. means git + thin + available + enabled
# @apps[appName]["repository"] # repository created
# @apps[appName]["thin"]       # thin configuration
# @apps[appName]["available"]  # nginx available config
# @apps[appName]["enabled"]    # nginx enabled config
# @apps[appName]["db"]         # existing database
# @apps[appName]["activated"]  # online? dropping...

# List   - [Just lists]
# Create - url, ports and first
#        - repository


# Requirements:

require 'erb'
require 'yaml'

class DeploymentActions

    def initialize

        @red = "\033[0;31m"
        @gre = "\033[0;32m"
        @yel = "\033[0;33m"
        @ncl = "\033[0m" #No colour

        @dataFile             = '/home/deploy/data/apps'
        @repositoriesFolder   = "/home/git/repositories/"
        @templatesFolder      = "/home/deploy/templates/"
        @productionFolder     = "/var/www/"
        @databaseYml          = "/config/database.yml"
        @nginxAvailableFolder = "/etc/nginx/sites-available/"
        @nginxEnabledFolder   = "/etc/nginx/sites-enabled/"

        @stop = false

        loadData

    end

    #-------------------------------------------------------------------------------
    #pragma mark – Getters to use on IRB
    # Print Variables

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

    def ptNormal msg
        print "#{@yel}#{msg}...#{@ncl}\n"
        # print "\r"
        @lastMsg = msg
    end

    def ptConfirm
        puts "#{@gre}#{@lastMsg}. [ok]     #{@ncl}"
    end

    def ptGreen msg
        puts "\n#{@gre}#{msg}#{@ncl}\n"
    end

    def ptError msg
        puts "\n#{@red}[Error] #{msg}!     #{@ncl}\n"
    end

    #-------------------------------------------------------------------------------
    # File methods

    def loadData

        if File.exists?(@dataFile)
            @apps = Marshal.load File.read(@dataFile)
            print "\r"
            ptGreen "Loading list of apps"
        else
            @apps = Hash.new
            print "\r"
            ptGreen "Created new list of apps"
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def saveData
        serialisedApps = Marshal.dump(@apps)
        savedFile = File.open(@dataFile, 'w') {|f| f.write(serialisedApps) }
        if savedFile.nil?
            ptError "Something went wrong saving the data file"
            return 1
        end
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def resetApplicationData

        port = 3000

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        saveData

    end

    #---------------------------------------------------------------------------
    # Secondary methods

    def createRepository appName

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Checks for repository:

        repositoryFolder = "#{@repositoriesFolder}#{appName}.git"

        if File.exists?(repositoryFolder)
            ptError "Repository folder already exists"
            return
        end

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Creates folder:

        ptNormal "Creating repository folder for #{appName}"

        createFolder = system( "sudo -u git mkdir #{repositoryFolder}" )

        unless createFolder
            ptError "Could not create git folder"
            @stop = true
            return
        else
            ptConfirm
        end

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Creates git bare respository

        ptNormal "Creating bare repository for #{appName}"

        createGit = system( "sudo -u git git init #{repositoryFolder}/ --bare" )

        unless createGit
            ptError "Could not create git repository"
            @stop = true
            return
        else
            ptConfirm
        end

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Saves the post-update hook:

        ptNormal "Creating hooks for #{appName}"

        createHook = system( "rvmsudo -u git ruby /home/git/scripts/createHook.rb #{appName}" )

        if createHook
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

    def cloneRepository appName

        ptNormal "Cloning repository for #{appName}"

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Cloning:

        cloneGit = system( "git clone #{@repositoriesFolder}#{appName}.git #{@productionFolder}#{appName}" )

        if cloneGit == true
            ptConfirm
        else
            ptError "Repository could not be cloned"
            @stop = true
            return
        end

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Permissions to 775:

        ptNormal "Changing repository's permissions"

        cloneGit = system( "chmod -R 775 #{@productionFolder}#{appName}" )

        if cloneGit == true
            ptConfirm
        else
            ptError "Could not change repository's permissions"
            @stop = true
            return
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def availNginxConfigFile appName

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Set variables for template:

        appUrl   = @apps[appName]["url"] #ERB
        appPorts = @apps[appName]["ports"]
        appFirst = @apps[appName]["first"]
        upstream = ""

        appPorts.times do |i|
          upstream += "    server 127.0.0.1:#{appFirst+i};\n"
        end

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
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

    def enableNginxConfigFile appName

        nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
        nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"
        
        ptNormal "Checking Nginx config file"

        if File.exists?(nginxConfigFile)

            unless File.exists?(nginxConfigLink)
                
                ptConfirm
                action = system( "ln -s #{nginxConfigFile} #{nginxConfigLink}" )
                unless action
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

    def deleteNginxConfigFile appName

        nginxConfigFile = "#{@nginxAvailableFolder}#{appName}.conf"
        nginxConfigLink = "#{@nginxEnabledFolder}#{appName}.conf"

        if File.exists?(nginxConfigLink)

            ptNormal "Deleting symlink for #{appName}"

            nginxCmd1 = system( "sudo rm #{nginxConfigLink}" )

            if nginxCmd1 == true
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
            nginxCmd2 = system( "sudo rm #{nginxConfigFile}" )

            if nginxCmd2 == true
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
    
    def saveThinConfigFile appName

        ptNormal "Saving Thin configuration for #{appName}"
        appPorts = @apps[appName]["ports"]
        appFirst = @apps[appName]["first"]
        thinCommand = system( "thin config -C /etc/thin/#{appName}.yml -c /var/www/#{appName} --servers #{appPorts} -e production -p #{appFirst}" )

        if thinCommand == true
          ptConfirm
        else
          ptError "Could not save Thin configuration for #{appName}"
          return
        end

        @apps[appName]["thin"] = true
        saveData

    end

     #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def deleteThinConfigFile appName

        ptNormal "Deleting Thin configuration for #{appName}"
        thinCmd = system( "rm /etc/thin/#{appName}.yml" ) #sudo

        if thinCmd == true
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
        actionNginx = system( "sudo service nginx start" )
        unless actionNginx
            ptError "Could not start Nginx"
            return
        else
            # ptConfirm
        end
    end

    def stopNginx
        # ptNormal "Stopping Nginx"
        command = system( "sudo service nginx stop" )
        unless command
            ptError "Could not stop Nginx"
            return
        else
            # ptConfirm
        end
    end


    def startThin appName
        command = system( "thin start -C /etc/thin/#{appName}.yml" )
        unless command
            ptError "Could not stop Thin"
            return
        else
            # ptConfirm
        end
    end

    def stopThin appName
        command = system( "thin stop -C /etc/thin/#{appName}.yml" )
        unless command
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

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # Iterates through all apps to stop server instances:

        @apps.each {|key, value|
            if value["online"]
                command = system( "thin stop -C /etc/thin/#{key}.yml" )
            end
        }

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    end

    def startServers

        ptNormal "Starting servers"

        ptNormal "Starting Thin"

        @apps.each {|key, value|
            if value["online"]
                command = system( "thin start -C /etc/thin/#{key}.yml" )
            end
        }

        startNginx

    end

    #---------------------------------------------------------------------------
    # Database methods

    def checkDbUser dbUser
        action = system( "sudo -u postgres psql -c '\\du' | grep #{dbUser}" )
    end

    def createDbUser dbUser, dbPassword
        action = system( "echo \"CREATE ROLE #{dbUser} WITH LOGIN ENCRYPTED PASSWORD '#{dbPassword}';\" | sudo -u postgres psql" )
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def checkDb dbName
        dbExists = system( "sudo -u postgres psql -c '\\l' | grep #{dbName}" )
    end

    def createProductionDb dbUser, dbName
        action = system( "sudo -u postgres createdb -O #{dbUser} #{dbName}" )
    end

    #---------------------------------------------------------------------------
    # Action methods

    def test
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    # List all applications names, ports used and url.
    #
    def list
        # Iterate through all apps and print
        @apps.each {|key, value|
            print @gre
            printf(" - %.15s - %d ports (%d) - %s\n", key.to_s, value['ports'], value['first'], value['url'])
            print @ncl
        }
        print "\n"
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    # Creates a new application
    #
    def create appName, appURL, appPorts
        
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

        loadData

        unless @apps[appName].nil?
          ptError "There is already an app with this name"
          return
        end

        # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
        # Create empty application:

        @apps[appName]               = Hash.new
        @apps[appName]["url"]        = appURL        # application dns
        @apps[appName]["ports"]      = appPorts.to_i # quantity of thin ports
       #@apps[appName]["first"]      = 3000 + x
       #@apps[appName]["installed"]  = false  # dropping it.. means git + thin + available + enabled
        @apps[appName]["repository"] = false  # repository created
        @apps[appName]["thin"]       = false  # thin configuration
        @apps[appName]["available"]  = false  # nginx available config
        @apps[appName]["enabled"]    = false  # nginx enabled config
        @apps[appName]["db"]         = false  # existing database
        @apps[appName]["activated"]  = false  # online? dropping...
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
        saveThinConfigFile appName  # thin

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Check database information and create it if needed
    #
    def deployDatabase appName

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

            newDB = createProductionDb dbUser, dbName
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
    def deploy appName

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

        # If already online, stop thin.

        if @apps[appName]["online"]
            stopNginx
            stopThin appName
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
        deployStep2 = system( "bundle package" )

        unless deployStep2
          ptError "Could not deploy step 2 - bundle package"
          return
        else
          ptConfirm
        end

        ptNormal "Executing 'bundle install'"
        deployStep3 = system( "bundle install --deployment" )

        unless deployStep3
          ptError "Could not deploy step 3 - bundle install"
          return
        else
          ptConfirm
        end

        # Check for migrations!

        migrationsFolder = "#{@productionFolder}#{appName}/db/migrate/"
        migrationsNumber = Dir.glob(File.join(migrationsFolder, '**', '*.rb')).count

        if migrationsNumber > 0
          ptNormal "#{migrationsNumber} migrations found."
          ptNormal "Migrating"
          deployStep4 = system( "RAILS_ENV=production rake db:migrate" )
          ptConfirm
        end

        ptNormal "Precompile assets"
        deployStep5 = system( "rake assets:precompile" )

        unless deployStep5
          ptError "Could not deploy step 5 - assets precompile"
          return
        else
          ptConfirm
        end

        # If all is fine, start thin, restart nginx.

        stopNginx
        startThin appName
        startNginx

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Rewrites the config files and resets thin
    #
    def reset appName

      if @apps[appName]["online"]
        
        stopThin appName

        deleteNginxConfigFile appName
        deleteThinConfigFile appName

        saveThinConfigFile
        availNginxConfigFile
        enableNginxConfigFile

        startThin appName
      
      end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Rewrites the config files and resets the servers
    #
    def resetAll        
        stopNginx
        resetApplicationData
        @apps.each {|key, value|
            reset key
        }
        startNginx
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Sets new value in the apps hash
    #
    def set appName, key, value
        @apps[appName][key] = value
        saveData
        resetAll
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Deletes configuration files and stops the application
    #
    def disable appName

        unless @apps[appName]["online"]
            ptError "#{appName.capitalize} already offline"
            return
        end

        stopNginx
        stopThin appName

        deleteNginxConfigFile appName
        deleteThinConfigFile appName

        startNginx

        @apps[appName]["online"] = false
        saveData

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def destroydb
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def destroy appName
        disable appName
        action = system( "rm -rf #{@productionFolder}#{appName} && sudo -u git rm -rf #{@repositoriesFolder}#{appName}.git" )
        @apps.delete(appName)
        saveData
        ptGreen "#{appName.capitalize} destroyed!"
    end

end
require 'erb'
require 'yaml'

class DeploymentActions

    def initialize

        @red = "\033[0;31m"
        @gre = "\033[0;32m"
        @yel = "\033[0;33m"
        @ncl = "\033[0m" #No colour

        @dataFile           = '/home/deploy/data/apps'
        @repositoriesFolder = "/home/git/repositories/"
        @templatesFolder    = "/home/deploy/templates/"
        @productionFolder   = "/var/www/"
        @databaseYml        = "/config/database.yml"

        loadData

    end

    #-------------------------------------------------------------------------------
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

        repositoryFolder = "#{@repositoriesFolder}#{appName}.git"

        if File.exists?(repositoryFolder)
            ptError "Repository folder already exists"
            return 1
        end

        ptNormal "Creating repository folder for #{appName}"

        createFolder = system( "sudo -u git mkdir #{repositoryFolder}" )

        unless createFolder
            ptError "Could not create git folder"
            return 2
        else
            ptConfirm
        end

        # Creates git bare respository

        ptNormal "Creating bare repository for #{appName}"

        createGit = system( "sudo -u git git init #{repositoryFolder}/ --bare" )

        unless createGit
            ptError "Could not create git repository"
            return 3
        else
            ptConfirm
        end

        # Saves the hook

        ptNormal "Creating hooks for #{appName}"

        createHook = system( "rvmsudo -u git ruby /home/git/scripts/createHook.rb #{appName}" )

        if createHook
            ptConfirm
        else
            print "\n"
            ptError "Could not create hook"
            return 4
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def cloneRepository appName

        ptNormal "Cloning repository for #{appName}"

        cloneGit = system( "git clone #{@repositoriesFolder}#{appName}.git #{@productionFolder}#{appName}" )

        if cloneGit == true
            ptConfirm
        else
            ptError "Repository could not be cloned"
            return 1
        end

        ptNormal "Changing repository's permissions"

        cloneGit = system( "chmod -R 775 #{@productionFolder}#{appName}" )

        if cloneGit == true
            ptConfirm
        else
            ptError "Could not change repository's permissions"
            return 2
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def saveNginxConfigFile appName

        appUrl   = @apps[appName]["url"] #ERB
        appPorts = @apps[appName]["ports"]
        appFirst = @apps[appName]["first"]
        upstream = ""

        appPorts.times do |i|
          upstream += "    server 127.0.0.1:#{appFirst+i};\n"
        end

        # Saves from template

        ptNormal "Saving Nginx configuration"

        file = "#{@templatesFolder}nginx.erb"
        nginxTemplate = ERB.new(File.read(file))
        nginxConfig = nginxTemplate.result(binding)
        nginxCommand = File.open("/etc/nginx/sites-available/#{appName}.conf", 'w') {|f| f.write(nginxConfig) }

        unless nginxCommand.nil?
          ptConfirm
        else
          ptError "Could not save Nginx configuration"
          return 1
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def deleteNginxConfigFile appName

        nginxConfigFile = "/etc/nginx/sites-available/#{appName}.conf"
        nginxConfigLink = "/etc/nginx/sites-enabled/#{appName}.conf"

        if File.exists?(nginxConfigLink)

            ptNormal "Deleting symlink for #{appName}"

            nginxCmd1 = system( "sudo rm #{nginxConfigLink}" )

            if nginxCmd1 == true
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
        thinCommand = system( "thin config -C /etc/thin/#{appName}.yml -c /var/www/#{appName} --servers #{appPorts} -e production -p #{appFirst}" ) #rvmsudo

        if thinCommand == true
          ptConfirm
        else
          ptError "Could not save Thin configuration for #{appName}"
          return
        end
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

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def resetServers

        ptNormal "Restarting servers"
        stopServers
        startServers

    end

    def stopServers

        ptNormal "Stopping Nginx"

        actionNginx = system( "sudo service nginx stop" )

        unless actionNginx
            ptError "Could not stop Nginx"
            return
        else
            ptConfirm
        end

        ptNormal "Stopping Thin"

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        # Iterates through all apps to stop server instances:

        @apps.each {|key, value|
            if value["activated"]
                command = system( "thin stop -C /etc/thin/#{key}.yml" )
            end
        }

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -



        # actionThin = system( "sudo service thin stop" )

        # unless actionThin
        #     ptError "Could not stop Thin"
        #     return
        # else
        #     ptConfirm
        # end

        # return actionNginx & actionThin

    end

    def startServers

        ptNormal "Starting servers"
        actionNginx = system( "sudo service nginx start" )

        unless actionNginx
            ptError "Could not restart Nginx"
            return
        else
            ptConfirm
        end

        ptNormal "Starting Thin"

        @apps.each {|key, value|
            if value["activated"]
                command = system( "thin start -C /etc/thin/#{key}.yml" )
            end
        }

        # actionThin = system( "sudo service thin start" )

        # unless actionThin
        #     ptError "Could not restart Thin"
        #     return
        # else
        #     ptConfirm
        # end

        # return actionNginx & actionThin

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

    def create appName, appURL, appPorts

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        loadData

        unless @apps[appName].nil?
            ptError "There is already an app with this name"
            return
        end

        @apps[appName]              = Hash.new
        @apps[appName]["url"]       = appURL
        @apps[appName]["ports"]     = appPorts.to_i
        @apps[appName]["installed"] = false
        @apps[appName]["db"]        = false
        @apps[appName]["activated"] = false

        resetApplicationData
        createRepository appName
        install appName

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def install appName

        if appName.nil?
            ptError "Define a name to install this application"
            return
        end

        if @apps.nil?
            loadData
        end

        if @apps[appName].nil?
            ptError "There is no app with this name"
            return
        end

        cloneRepository appName
        saveNginxConfigFile appName
        saveThinConfigFile appName

        @apps[appName]["installed"] = true

        saveData

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def createdb appName

        if @apps[appName]["db"] == true
            ptGreen "Database already set."
            return
        end

        dbConfigFile = "#{@productionFolder}#{appName}#{@databaseYml}"

        ptNormal "Checking file: #{dbConfigFile}"

        unless File.exists?(dbConfigFile)
            ptError "Database file does not exist"
            return
        end

        dbDetails = YAML.load_file(dbConfigFile)

        productionDB = dbDetails['production']
        ptNormal "Production db details:"
        puts productionDB

        if productionDB.nil?
            ptNormal "Nothing to do with the database"
            return
        end

        dbAdapter = productionDB['adapter']

        if dbAdapter == "sqlite3"
            ptGreen "Sqlite3 detected!"
            return
        end

        dbName = productionDB['database']
        dbUser = productionDB['username']
        dbPass = productionDB['password']

        ptNormal "Name: #{dbName}"
        ptNormal "User: #{dbUser}"
        ptNormal "Pass: #{dbPass}"

        ptNormal "Checking DB user existence"
        userExistent = checkDbUser dbUser

        unless userExistent

            ptConfirm
            ptNormal "Creating new user '#{dbUser}'"

            newUser = createDbUser dbUser, dbPass
            unless newUser
                ptError "Unable to create DB user"
                return 2
            else
                ptConfirm
            end

        else
            ptConfirm
        end

        ptNormal "Checking DB existence"
        dbExistent = checkDb dbName

        unless dbExistent

            ptConfirm
            ptNormal "Creating new database"

            newDB = createProductionDb dbUser, dbName
            unless newDB
                ptError "Unable to create database"
                return 3
            else
                ptConfirm
                @apps[appName]["db"] = true
            end

        else
            ptConfirm
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def enable appName

        unless @apps[appName]["installed"]
            ptError "Install #{appName} before enabling it"
            return
        end

        nginxConfigFile = "/etc/nginx/sites-available/#{appName}.conf"
        nginxConfigLink = "/etc/nginx/sites-enabled/#{appName}.conf"
        
        ptNormal "Checking Nginx config file"

        if File.exists?(nginxConfigFile)

            unless File.exists?(nginxConfigLink)
                
                ptConfirm
                action = system( "ln -s #{nginxConfigFile} #{nginxConfigLink}" )
                unless action
                    ptError "Could not symlink file"
                    return
                end

            end

        else
            ptError "Config file non-existent"
            return
        end

        # if 
            stopServers
            @apps[appName]["activated"] = true
            saveData
            startServers
        # end
        
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def deploy appName

        ptGreen "[Deploying]"
        
        if @apps[appName]["installed"]
            ptNormal "Checking application state"
        else
            ptError "This application is not installed"
            return
        end
        
        if @apps[appName]["activated"]
            ptConfirm
            ptGreen "#{appName.capitalize} activated."
        else
            enable appName
        end

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        ptNormal "Checking database data"

        createdb appName

        # checkDbUser dbUser
        # createDbUser dbUser, dbPassword
        # checkDb dbName
        # createProductionDb dbUser, dbName

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        ptNormal "Accessing folder"

        Dir.chdir "#{@productionFolder}#{appName}"
        # deployStep1 = system( "cd #{@productionFolder}#{appName}" )

        # unless deployStep1
        #     ptError "Could not deploy step 1 - cd"
        #     return
        # else
        #     ptConfirm
        # end

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        ptNormal "Bundle package"
        deployStep2 = system( "bundle package" )

        unless deployStep2
            ptError "Could not deploy step 2 - bundle package"
            return
        else
            ptConfirm
        end

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        ptNormal "Bundle install for production"
        deployStep3 = system( "bundle install --deployment" )

        unless deployStep3
            ptError "Could not deploy step 3 - bundle install"
            return
        else
            ptConfirm
        end

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        ptNormal "Migrate database"
        deployStep4 = system( "RAILS_ENV=production rake db:migrate" )

        ptConfirm
        
        # unless deployStep4
        #     ptConfirm
        # else
        #     ptError "Could not deploy step 4 - db migrate"
        #     return
        # end

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        ptNormal "Precompile assets"
        deployStep5 = system( "rake assets:precompile" )

        unless deployStep5
            ptError "Could not deploy step 5 - assets precompile"
            return
        else
            ptConfirm
        end

        #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        resetServers

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def reset appName

        if @apps[appName]["installed"] & @apps[appName]["activated"]
            deleteNginxConfigFile appName
            deleteThinConfigFile appName
            saveNginxConfigFile appName
            saveThinConfigFile appName
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def resetAll
        
        stopServers

        resetApplicationData

        @apps.each {|key, value|
            reset key
        }

        startServers

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def set appName, key, value
        @apps[appName][key] = value
        saveData
        resetAll
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def disable appName

        unless @apps[appName]["activated"]
            ptError "#{appName.capitalize} already disabled"
            return
        end

        deleteConf = deleteNginxConfigFile appName

        if deleteConf
            @apps[appName]["activated"] = false
            saveData
        end

    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def destroydb
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def uninstall appName

        deleteThinConfigFile appName
        deleteNginxConfigFile appName

        @apps[appName]["installed"] = false

        saveData
    end

    #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    def destroy appName
        uninstall appName
        action = system( "sudo -u git rm -rf #{@productionFolder}#{appName} && sudo -u git rm -rf #{@repositoriesFolder}#{appName}.git" )
        @apps.delete(appName)
        saveData
        ptGreen "#{appName.capitalize} destroyed!"
    end

end
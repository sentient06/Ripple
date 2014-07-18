# Ruby Deployment for Humans
# Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Git
  
  def initialize(rubyPath, gitUser, repositoriesFolder, productionFolder)
    @put                = Put.new
    @system             = System.new
    @gitUser            = gitUser
    @rubyPath           = rubyPath ? rubyPath : "ruby"
    @repositoriesFolder = repositoriesFolder
    @productionFolder   = productionFolder
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Creates application's repository directory
  #
  def createRepositoryDirectory(appName)
    repositoryFolder = "#{@repositoriesFolder}#{appName}.git"

    if File.exists?(repositoryFolder)
      @put.error "Repository directory already exists"
      return
    end

    # Creates directory:
    @put.normal "Creating repository directory for #{appName}"
    createFolder = @system.execute("sudo -u #{@gitUser} mkdir #{repositoryFolder}")

    if createFolder.success?
      @put.confirm
      return repositoryFolder
    else
      @put.error "Could not create git directory"
      @put.error "sudo -u #{@gitUser} mkdir #{repositoryFolder}"
      return 1
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Deletes application's repository directory
  #
  def deleteRepositoryDirectory(appName)
    repositoryFolder = "#{@repositoriesFolder}#{appName}.git"
    deleteFolder = @system.execute("sudo -u #{@gitUser} rm -rf #{repositoryFolder}")
  end

  def createBareRepository(repositoryFolder, appName)
    @put.normal "Creating bare repository for #{appName}"
    createGit = @system.execute("sudo -u #{@gitUser} git init #{repositoryFolder}/ --bare")
    if createGit.success?
      @put.confirm
      return 0
    else
      @put.error "Could not create git repository"
      return 1
    end
  end

  def createHook(appName)
    @put.normal "Creating hooks for #{appName}"
    createHook = @system.execute("sudo -u #{@gitUser} #{@rubyPath} /home/#{@gitUser}/scripts/createHook.rb #{appName}")
    if createHook.success?
      @put.confirm
      return 0
    else
      print "\n"
      @put.error "Could not create hook"
      @put.error "sudo -u #{@gitUser} #{@rubyPath} /home/#{@gitUser}/scripts/createHook.rb #{appName}"
      return 1
    end
  end

  # -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

  def createRepository(appName, createHook=true)
    # Checks for repository:
    repositoryFolder = createRepositoryDirectory(appName)
    if repositoryFolder == 1
      exit
    end
    # Creates git bare repository
    success = createBareRepository(repositoryFolder, appName)
    if success == 1
      return 1
    end
    # Saves the post-update hook:
    if createHook==true
      success = createHook appName
      if success == 1
        return 1
      end
    end
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

end
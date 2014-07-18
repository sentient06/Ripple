# Ripple
# Copyright (c) 2014 Giancarlo Mariot. All rights reserved.
#------------------------------------------------------------------------------

class Files

  def initialize(productionFolder)
    @productionFolder = productionFolder
  end

  def parseGemfile(filePath)
    allGems = []
    skip = false
    File.open(filePath).read.each_line do |i|
      i = i.split
      if i[0] == "group"
        if i[1] == ":development" || i[1] == ":test"
          skip = true
        end
      end
      unless skip
        if i[0] == "gem"
          name = i[1].gsub(",","")
          gemName = eval name
          allGems.push(gemName)    
        end
      else
        if i[0] == "end"
          skip = false
        end
      end
    end

    return allGems
    # allGems.include? 'pg'
    # allGems.include? 'thin'
    # allGems.include? 'sqlite3'
  end

  def findGemForApp(gemName, appName)
    f = "#{@productionFolder}#{appName}/Gemfile"
    g = parseGemfile(f)
    g.include? gemName
  end

end
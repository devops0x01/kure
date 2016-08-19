require "fileutils"

## Versioning commands are implemented here.
class Kure
  REPOSITORY_DIR         = ".kure"
  REPOSITORY_DATA_DIR    = "#{REPOSITORY_DIR}/data"
  REPOSITORY_STAGING_DIR = "#{REPOSITORY_DIR}/staged"

  PENDING_FILE    = "#{REPOSITORY_DIR}/pending"
  PROPERTIES_FILE = "#{REPOSITORY_DIR}/properties"
  META_FILE       = "#{REPOSITORY_DIR}/meta"
  

  def initialize()
    # If .kure exist, attempt to load the repository.
  end
  
  ## Create a new repository in .kure if it doesn't exist.
  ## If it already exists, show an error and exit.
  ## TODO: complete functionality
  def create(name)
    Dir.mkdir(REPOSITORY_DIR)
    Dir.mkdir(REPOSITORY_DATA_DIR)
    Dir.mkdir(REPOSITORY_STAGING_DIR)
    File.new(PENDING_FILE,"w").close
    File.new(META_FILE,"w").close
    File.new(PROPERTIES_FILE,"w").close
  end
  
  def add(items)
    ## Add the indicated items to the repository's pending list
    f = File.open(PENDING_FILE,"w+")
    items.each do |i|
      if File.exists?(i) then
        f.puts(i)
      else
        ## TODO: file does not exist, omitting
        ## TODO: should I truncate the pending list here?
        f.close()
        return false
      end
    end
    f.close()
    return true
  end
  
  def commit(options=nil)
    ## TODO: compare files so that files which match the last version
    ##       are only committed if confirmed
  
    ## Foreach pending file rename the existing copy in data
    ## and then copy in the new one. This is an extremely inefficient
    ## method for versioning files and is only a place holder at this time.
    ## A better method is planned for a future iteration.
    
    ## First copy each file to a staging directory.
    ## If a file is missing, error out and delete the staged files
    ## then return false. This makes for an easy roll back.
    success = true
    files = File.readlines(PENDING_FILE)
    files.each do |f|
      f.chomp!
      if File.exists?(f) then
        ## If it exists we will attempt a copy to staging
        FileUtils.copy(f,"#{REPOSITORY_STAGING_DIR}/#{f}")
        unless File.exists?("#{REPOSITORY_STAGING_DIR}/#{f}") then
          ## If copy failed then success is set to false and we need to roll back.
          success = false
          break
        end
      else
        ## If a file indicated by the pending list doesn't exist
        ## then success is set to false and we need to roll back.
        success = false
        break
      end
    end
    if success then
      ## If we successfully copied to staging then we can now move everything
      ## to data.
      
      ## First ensure we don't overwrite the last version.
      files.each do |f|
        f.chomp!
        if File.exists?("#{REPOSITORY_DATA_DIR}/#{f}") then
          FileUtils.mv("#{REPOSITORY_DATA_DIR}/#{f}","#{REPOSITORY_DATA_DIR}/#{f}.#{timestamp()}")
        end
        ## Now move in the pending file.
        FileUtils.mv("#{REPOSITORY_STAGING_DIR}/#{f}","#{REPOSITORY_DATA_DIR}/#{f}")
      end
      ## We have completed committing the staged files so clear the pending list.
      File.truncate(PENDING_FILE,0)
      return true
    else
      ## Success was false, so delete any staged files as part of roll back.
      ## TODO: how should I handle the pending list here?
      entries = Dir.entries(REPOSITORY_STAGING_DIR)
      entries.delete("..")
      entries.delete(".")
      entries.each do |e|
        FileUtils.rm("#{REPOSITORY_STAGING_DIR}/#{e}")
      end
      return false
    end
  end
  
  def get(items=nil)
    
  end
  
  def delete(items)
    
  end
  
  def move(src,dest)
    
  end
  
  def rename(from,to)
    
  end
  
  def log(options=nil)
    
  end
  
  def timestamp()
    return Time.now.to_i
  end
  
  private :timestamp
  
end

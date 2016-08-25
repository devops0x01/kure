require "fileutils"
require "yaml"
require File.dirname(__FILE__) + "/log_entry.rb"
require File.dirname(__FILE__) + "/change.rb"

## Versioning commands are implemented here.
class Kure
  REPOSITORY_DIR          = ".kure"
  REPOSITORY_VERSIONS_DIR = "#{REPOSITORY_DIR}/versions"
  REPOSITORY_STAGING_DIR  = "#{REPOSITORY_DIR}/staged"

  PENDING_FILE      = "#{REPOSITORY_DIR}/pending"
  STATUS_FILE       = "#{REPOSITORY_DIR}/status"
  PROPERTIES_FILE   = "#{REPOSITORY_DIR}/properties"
  LAST_VERSION_FILE = "#{REPOSITORY_DIR}/last_version"
  

  def initialize(path=".")
    # TODO: If .kure exist, attempt to load relevant information
    if Dir.exists?(REPOSITORY_DIR) then
      self.load_properties(path)
      f = File.open(LAST_VERSION_FILE,"r")
      @last_version = f.read(@last_version).to_i
      f.close
      @status = self.load_status()
    end
  end
  
  ## Create a new repository in .kure if it doesn't exist.
  ## If it already exists, show an error and exit.
  ## TODO: complete functionality
  def create(name)
    @status = Hash.new

    Dir.mkdir(name)

    Dir.mkdir("#{name}/#{REPOSITORY_DIR}")
    Dir.mkdir("#{name}/#{REPOSITORY_VERSIONS_DIR}")
    Dir.mkdir("#{name}/#{REPOSITORY_STAGING_DIR}")
    File.new("#{name}/#{PENDING_FILE}","w").close

    f = File.new("#{name}/#{STATUS_FILE}","w")
    f.print(@status.to_yaml)
    f.close

    

    @last_version = -1
    f = File.new("#{name}/#{LAST_VERSION_FILE}","w")
    f.print(@last_version)
    f.close

    @properties = Hash.new
    @properties["name"] = name
    @properties["remote"] = nil
    @properties["clone"] = false
    f = File.new("#{name}/#{PROPERTIES_FILE}","w")
    f.print(@properties.to_yaml)
    f.close
  end

  def clone(src)
    self.load_properties(src)
    @properties["remote"] = File.absolute_path(src)
    @properties["clone"] = true
    FileUtils.cp_r(src,@properties["name"])
    FileUtils.cd(@properties["name"])
    f = File.new(PROPERTIES_FILE,"w")
    f.print(@properties.to_yaml)
    f.close
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
  
  def commit(message="")
    ## TODO: compare files so that files which match the last version
    ##       are only committed if confirmed - or follow gits method and 
    ##       only make modified files available for check in...
  
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
      current_version_dir = "#{REPOSITORY_VERSIONS_DIR}/#{@last_version + 1}"
      Dir.mkdir(current_version_dir)
      Dir.mkdir("#{current_version_dir}/data")
      ## TODO: I think I can move all of these with a glob now...
      files.each do |f|
        f.chomp!
        FileUtils.mv("#{REPOSITORY_STAGING_DIR}/#{f}","#{current_version_dir}/data/#{f}")
      end

      ## If the last version number was -1 then this is the initial version.
      ## We need to create an image file from scratch. Future commits will start by
      ## loading the last versions image file and edit the data to create the new one.
      image = Hash.new
      unless @last_version == -1 then
        image = YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{@last_version}/image.yaml"))
      end
      
      files.each do |f|
        image[f] = @last_version + 1
      end
      
      f = File.new("#{current_version_dir}/image.yaml","w")
      f.print(image.to_yaml)
      f.close
      
      @last_version += 1
      f = File.open(LAST_VERSION_FILE,"w")
      f.print(@last_version)
      f.close
      ## We have completed committing the staged files so clear the pending list.
      self.clear_pending()

      ## Create a log message
      log_entry = LogEntry.new
      log_entry.version = @last_version
      log_entry.date_time = Time.now
      log_entry.commit_message = message
      log_entry.file_list = files

      f = File.open("#{REPOSITORY_VERSIONS_DIR}/#{@last_version}/log","w+")
      f.print(log_entry.to_yaml)
      f.close

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

  def get(version=@last_version,items=nil)
    # TODO: handle bad version number some how...
    image = YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{version}/image.yaml"))
    if items == nil then
      image.keys.each do |k|
        FileUtils.cp("#{REPOSITORY_VERSIONS_DIR}/#{image[k].to_s}/data/#{k}",k)
      end
    else
      items.each do |i|
        FileUtils.cp("#{REPOSITORY_VERSIONS_DIR}/#{image[i]}/data/#{i}",i)
      end
    end
  end
  
  def delete(items)
    items.each do |i|
      FileUtils.rm(i)
      c = Change.new
      c.action = "delete"
      c.parameters = i
      @status[i] = c
    end
    self.save_status()
  end
  
  def move(src,dest)
    c = Change.new
    c.action = "move"
    c.parameters = [src,dest]
    # TODO: physically move the file
    # TODO: set status
    @status[src] = c
    self.save_status
  end
  
  def rename(from,to)
    c = Change.new
    c.action = "rename"
    c.parameters = [from,to]
    # TODO: rename the file
    # TODO: set status
    @status[from] = c
    self.save_status
  end
  
  def log(version=@last_version)
    return YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{version}/log"))
  end

  def status

    return @status

    ## notes:

    ##require "digest"
    ##require "digest/md5"
    ##Digest::MD5.hexdigest
    ##Digest::SHA2.hexdigest


    ## read in status file data
    ## check for file modifications
    ## check for unknown files
    ## check for missing files
  end

  def load_properties(path)
    @properties = YAML.load(File.read(path + "/" +  PROPERTIES_FILE))
  end
 
  def load_status()
    @status = YAML.load(File.read(STATUS_FILE))
  end

  def save_status()
    f = File.open(STATUS_FILE,"w")
    f.print @status.to_yaml
    f.close
  end

  def clear_pending()
    File.truncate(PENDING_FILE,0)
  end

end

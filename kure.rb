require "fileutils"
require "yaml"
require File.dirname(__FILE__) + "/log_entry.rb"
require File.dirname(__FILE__) + "/change.rb"

require "digest/md5"


## Versioning commands are implemented here.
class KureOrig
  REPOSITORY_DIR          = ".kure"
  REPOSITORY_VERSIONS_DIR = "#{REPOSITORY_DIR}/versions"
  REPOSITORY_STAGING_DIR  = "#{REPOSITORY_DIR}/staged"

  PENDING_FILE      = "#{REPOSITORY_DIR}/pending"
  STATUS_FILE       = "#{REPOSITORY_DIR}/status"
  PROPERTIES_FILE   = "#{REPOSITORY_DIR}/properties"
  LAST_VERSION_FILE = "#{REPOSITORY_DIR}/last_version"

  attr_reader :pending,:status


  def initialize(path=".")
    if Dir.exists?(REPOSITORY_DIR) then
      self.load_properties(path)
      f = File.open(LAST_VERSION_FILE,"r")
      @last_version = f.read(@last_version).to_i
      f.close
      @status = self.load_status()
      @pending = YAML.load(File.read(PENDING_FILE))
    end
  end

  ## Create a new repository in .kure if it doesn't exist.
  ## If it already exists, return an error
  def create(name)
    if Dir.exists?(name) then
      return false
    else
      @status     = Hash.new
      @pending    = Hash.new
      @properties = Hash.new

      Dir.mkdir(name)
      Dir.mkdir("#{name}/#{REPOSITORY_DIR}")
      Dir.mkdir("#{name}/#{REPOSITORY_VERSIONS_DIR}")
      Dir.mkdir("#{name}/#{REPOSITORY_STAGING_DIR}")

      f = File.new("#{name}/#{PENDING_FILE}","w")
      f.print(@pending.to_yaml)
      f.close

      f = File.new("#{name}/#{STATUS_FILE}","w")
      f.print(@status.to_yaml)
      f.close

      @last_version = -1
      f = File.new("#{name}/#{LAST_VERSION_FILE}","w")
      f.print(@last_version)
      f.close

      @properties["name"]   = name
      @properties["remote"] = nil
      @properties["clone"]  = false

      f = File.new("#{name}/#{PROPERTIES_FILE}","w")
      f.print(@properties.to_yaml)
      f.close

      return true
    end
  end

  def clone(src,dest='')
    clone_dir = Dir.pwd + "/" + File.basename(src)
    src_abs = File.absolute_path(src)

    if clone_dir == src_abs then
      ## Cannot create the clone in the same place as the original.

      return false
    else
      ## Create a copy of the repository and mark it as a clone in the properties.
      self.load_properties(src)
      @properties["remote"] = src_abs
      @properties["clone"] = true
      if dest == '' then
        dest = @properties["name"]
      end
      FileUtils.cp_r(src,dest)
      FileUtils.cd(dest)
      f = File.new(PROPERTIES_FILE,"w")
      f.print(@properties.to_yaml)
      f.close

      return true
    end
  end

  def add(items)
    ## Add the indicated items to the repository's pending list
    items.each do |i|
      if @status.has_key?(i) then
          # TODO: add delete and move to pending here
          c = @status[i]
          @pending[i] = c
          @status.delete(i)
      else
        if File.exists?(i) then
          c = Change.new
          c.action = "add"
          c.parameters = i
          @pending[i] = c
        else
          return false
        end
      end
    end

    self.save_pending
    self.save_status

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


    ## If the last version number was -1 then this is the initial version.
    ## We need to create an image file from scratch. Future commits will start by
    ## loading the last versions image file and edit the data to create the new one.
    @image = Hash.new
    unless @last_version == -1 then
      @image = YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{@last_version}/image.yaml"))
    end

    puts @image

    @pending.keys.each do |f|

      ## Go through the pending files and setup the version to reflect the changes.
      ##    Modified files and new files are added to the version data directory
      ##    then recorded in the image file.
      ##
      ##    Deleted files are removed from the loaded image hash so they are not
      ##    Propagated to the this version.
      ##
      ##    Moved files have there paths changed in the image hash to reflect the
      ##    new directory/name. The file with the new name/placement is moved into
      ##    the appropriate part of this version's data directory.
      ##
      if @pending[f].action == "add" then
        puts "adding: <#{f}>"
        create_missing_dirs(f,REPOSITORY_STAGING_DIR)
        if File.file?(f) then
          FileUtils.copy(f,"#{REPOSITORY_STAGING_DIR}/#{f}")
        else
          FileUtils.copy_entry(f,"#{REPOSITORY_STAGING_DIR}/#{f}")
        end
      elsif @pending[f].action == "delete" then
        puts "removing: <#{f}>"
        @image.delete(f)
      elsif @pending[f].action == "move" then
        puts "moving: <#{f}>"
        version = @image[f]
        @image.delete(f)
        newName = @pending[f].parameters[1]
        @image[newName] = (version + 1)
        FileUtils.copy(newName,"#{REPOSITORY_STAGING_DIR}/#{newName}")
      end
    end

    puts @image

    ## Move items from staging to data.
    current_version_dir = "#{REPOSITORY_VERSIONS_DIR}/#{@last_version + 1}"
    Dir.mkdir(current_version_dir)
    Dir.mkdir("#{current_version_dir}/data")

    entries = Dir.entries("#{REPOSITORY_STAGING_DIR}")
    entries.delete('.')
    entries.delete('..')
    entries.each do |i|
      FileUtils.mv("#{REPOSITORY_STAGING_DIR}/#{i}","#{current_version_dir}/data/#{i}")
    end

    @pending.keys.each do |f|
     # if @pending[f].action == "add" then
     #   dirname = File.dirname(f)
     #   if dirname != "" then
     #     ## this file is located in a directory so add the
     #     ## directories before trying to copy the file to data
     #     FileUtils.mkdir_p("#{current_version_dir}/data/#{dirname}")
     #   end
     #   FileUtils.mv("#{REPOSITORY_STAGING_DIR}/#{f}","#{current_version_dir}/data/#{f}")
     # elsif @pending[f].action == "move" then
      if @pending[f].action == "move" then
        newName = @pending[f].parameters[1]
        FileUtils.mv("#{REPOSITORY_STAGING_DIR}/#{newName}","#{current_version_dir}/data/#{newName}")
      end
    end

    ## Set the version for each file recorded in the image file.
    @pending.keys.each do |f|
      if @pending[f].action == "add" then
        @image[f] = @last_version + 1
      end
    end

    self.save_image

    @last_version += 1
    self.save_version

    ## Create a log message
    self.log_entry(message)
    self.save_log()

    ## We have completed committing the staged files so clear the pending list.
    @pending = Hash.new
    self.save_pending

    self.clear_staging_dir

  end

  def get(version=@last_version,items=nil)
    # TODO: handle bad version number some how...
    # TODO: bandaided this to create dirs if they are missing, but then it
    #       wastes time recopying the same dir again when it gets to it in the list
    image = YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{version}/image.yaml"))
    if items == nil then
      image.keys.each do |k|
        item = "#{REPOSITORY_VERSIONS_DIR}/#{image[k].to_s}/data/#{k}"
        create_missing_dirs(k)
        if File.file?(item) then
          FileUtils.cp(item,k)
        else
          FileUtils.copy_entry(item,k)
        end
      end
    else
      items.each do |i|
        item = "#{REPOSITORY_VERSIONS_DIR}/#{image[i]}/data/#{i}"
        create_missing_dirs(item,i)
        if File.file?(item) then
          FileUtils.cp(item,i)
        else
          FileUtils.copy_entry(i)
        end
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
    FileUtils.mv(src,dest)
    @status[src] = c
    self.save_status
  end

  def get_log(version=@last_version)
    return YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{version}/log"))
  end

  def get_status
    unless @last_version == -1 then
      @image = YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{@last_version}/image.yaml"))
    end
    @image.each do |k,v|
      unless File.exists?(k) then
        #TODO: need to go see how I am handling deletes...
        puts "deleted: " + k.to_s
      else
        if File.file?(k) then
          unless File.size(k) == File.size("#{REPOSITORY_VERSIONS_DIR}/#{v}/data/" + k) then
            puts "changed: " + k
          else
            if Digest::MD5.hexdigest(File.read(k)) !=
               Digest::MD5.hexdigest(File.read("#{REPOSITORY_VERSIONS_DIR}/#{v}/data/" + k)) then
              puts "changed: " + k
            end
          end
        end
      end
    end
    ## check for new files
    #next, get a recursive listing of all files in the working directory
    #and check if they are in the repository. If not, they must be new.
    (Dir['**/*'].reject {|f|File.directory?(f)}).each do |p|
      unless @image.has_key?(p) then
        puts "new: " + p
      end
    end
  end

  def diff(path)
    results = []

    wf = File.open(path,'r')
    wf_lines = wf.readlines()
    wf.close

    @image = YAML.load(File.read("#{REPOSITORY_VERSIONS_DIR}/#{@last_version}/image.yaml"))
    rf = File.open(REPOSITORY_VERSIONS_DIR + "/" + @image[path].to_s + "/data/" + path,'r')
    rf_lines = rf.readlines()
    rf.close

    lines1 = nil
    lines2 = nil
    if rf_lines.size > wf_lines.size then
      lines1 = rf_lines
      lines2 = wf_lines
    else
      lines1 = wf_lines
      lines2 = rf_lines
    end

    c = 0
    lines1.each do |line|
      if lines2[c] then
        if line == lines2[c] then
          puts line
        else
          puts "[1] " + line
          puts "[2] " + lines2[c]
        end
      else
        puts "_ " + line
      end
      c += 1
    end

    return results
  end
  
  def get_current_version()
    return @last_version
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
    @pending = Hash.new
    f = File.open("#{PENDING_FILE}","w")
    f.print(@pending.to_yaml)
    f.close
  end

  def save_pending()
    f = File.open(PENDING_FILE,"w")
    f.print(@pending.to_yaml)
    f.close()
  end

  def save_version()
    f = File.open(LAST_VERSION_FILE,"w")
    f.print(@last_version)
    f.close
  end

  def save_image()
    f = File.new("#{REPOSITORY_VERSIONS_DIR}/#{@last_version + 1}/image.yaml","w")
    f.print(@image.to_yaml)
    f.close
  end

  def clear_staging_dir()
    entries = Dir.entries(REPOSITORY_STAGING_DIR)
    entries.delete("..")
    entries.delete(".")
    entries.each do |e|
      if File.file?(e) then
        FileUtils.rm("#{REPOSITORY_STAGING_DIR}/#{e}")
      else
        FileUtils.rm_rf("#{REPOSITORY_STAGING_DIR}/#{e}")
      end
    end
  end

  def log_entry(message)
    @log = LogEntry.new
    @log.version = @last_version
    @log.date_time = Time.now
    @log.commit_message = message
    @log.file_list = @pending
  end

  def save_log()
    f = File.open("#{REPOSITORY_VERSIONS_DIR}/#{@last_version}/log","w")
    f.print(@log.to_yaml)
    f.close
  end

  def create_missing_dirs(file,dir='.')
    dirname = File.dirname(file)
    puts "creating dirs: #{dirname}"
    if dirname != "" then
      ## this file is located in a directory so add the
      ## directories before trying to copy the file to staging
      FileUtils.mkdir_p("#{dir}/#{dirname}")
    end
  end
end





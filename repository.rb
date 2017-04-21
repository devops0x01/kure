
require "fileutils"
require "yaml"

module Kure

  class Repository
    attr_reader :base_dir, :versions_dir, :staging_dir,
                :pending_file, :status_file, :properties_file,
                :last_version_file, :last_version, :image,
                :path, :status, :pending, :properties
    def initialize(path=".")
      @base_dir     = ".kure"
      @versions_dir = @base_dir + '/versions'
      @staging_dir  = @base_dir + '/staged'

      @pending_file      = @base_dir + '/pending'
      @status_file       = @base_dir + '/status'
      @properties_file   = @base_dir + '/properties'
      @last_version_file = @base_dir + '/last_version'

      @path = path

      if Dir.exists?(path + '/' + @base_dir) then
        self.load_properties(path)
        self.load_status(path)
        self.load_pending(path)
        self.load_last_version(path)
        self.load_image(path)
      else
        @properties = Hash.new
        @image      = Hash.new

        @properties[:name]  = ""
        @properties[:clone] = false
      end
    end

    def save_properties(path='.')
        f = File.open(path + '/' + @properties_file,"w")
        f.print(@properties.to_yaml)
        f.close
    end

    def set_property(key,value)
      @properties[key] = value
    end

    def load_properties(path='.')
      @properties = YAML.load(File.read(path + "/" +  @properties_file))
    end

    def load_pending(path='.')
      @pending = YAML.load(File.read(path + '/' + @pending_file))
    end

    def load_status(path='.')
      @status = YAML.load(File.read(path + '/' + @status_file))
    end

    def load_last_version(path='.')
      File.open(path + '/' + @last_version_file,"r") do |f|
        @last_version = f.read().to_i
      end
    end

    def save_status(path='.')
      f = File.open(path + '/' + @status_file,"w")
      f.print @status.to_yaml
      f.close
    end

    def clear_pending(path='.')
      @pending = Hash.new
      f = File.open("#{path + '/' + @pending_file}","w")
      f.print(@pending.to_yaml)
      f.close
    end

    def clear_status(path='.')
      @status = Hash.new
      f = File.open("#{path + '/' + @status_file}","w")
      f.print(@status.to_yaml)
      f.close
    end

    def save_pending(path='.')
      f = File.open(path + '/' + @pending_file,"w")
      f.print(@pending.to_yaml)
      f.close()
    end
    def save_version(path='.')
      f = File.open(path + '/' + @last_version_file,"w")
      f.print(@last_version)
      f.close
    end

    def save_image(path='.')
      f = File.new("#{path}/#{@versions_dir}/#{@last_version + 1}/image.yaml","w")
      f.print(@image.to_yaml)
      f.close
    end

    def save_log(path='.')
      f = File.open("#{path}/#{@versions_dir}/#{@last_version}/log","w")
      f.print(@log.to_yaml)
      f.close
    end

    def load_log(version=@last_version, path='.')
      YAML.load(File.read("#{path}/#{@versions_dir}/#{version}/log"))
    end

    def load_image(path='.')
      unless @last_version == -1 then
        #File.open("#{path}/#{@versions_dir}/#{@last_version + 1}/image.yaml","r") do |f|
        File.open("#{path}/#{@versions_dir}/#{@last_version}/image.yaml","r") do |f|
          @image = YAML.load(f.read())
        end
      else
        @image = Hash.new
      end
    end

    def clear_staging(path='.')
      stage_path = path + "/" + @staging_dir
      entries = Dir.entries(stage_path)
      entries.delete("..")
      entries.delete(".")
      entries.each do |e|
        if File.file?(e) then
          FileUtils.rm("#{stage_path}/#{e}")
        else
          FileUtils.rm_rf("#{stage_path}/#{e}")
        end
      end 
    end

  end

end







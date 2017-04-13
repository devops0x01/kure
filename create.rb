require File.dirname(__FILE__) + '/command.rb'

module Kure
  class Create < Command

    def initialize(repository, name, path='.')
      super(repository)
      @name = name
      @path = path
    end

    def execute()
      if Dir.exists?(@name) then
        return false
      else
        status     = Hash.new
        pending    = Hash.new
        properties = Hash.new
        repo_path  = @path + '/' + @name

        Dir.mkdir(repo_path)
        Dir.mkdir("#{repo_path}/#{@repository.base_dir}")
        Dir.mkdir("#{repo_path}/#{@repository.versions_dir}")
        Dir.mkdir("#{repo_path}/#{@repository.staging_dir}")
  
        f = File.new("#{repo_path}/#{@repository.pending_file}","w")
        f.print(pending.to_yaml)
        f.close
        @repository.load_pending(@name)
  
        f = File.new("#{repo_path}/#{@repository.status_file}","w")
        f.print(status.to_yaml)
        f.close
        @repository.load_status(@name)
  
        last_version = -1
        f = File.new("#{repo_path}/#{@repository.last_version_file}","w")
        f.print(last_version)
        f.close
        @repository.load_last_version(@name)
  
        properties[:name]  = @name
        properties[:clone] = false
  
        f = File.new("#{repo_path}/#{@repository.properties_file}","w")
        f.print(properties.to_yaml)
        f.close
        @repository.load_properties(@name)
  
        return true
      end
    end

  end


end







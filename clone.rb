#require "digest/md5"
#require File.dirname(__FILE__) + '/change.rb'
require File.dirname(__FILE__) + '/command.rb'

module Kure
  class Clone < Command

    def initialize(repository,dest)
      super(repository)
      @dest = dest
    end

    def execute()
      dest_abs = File.absolute_path(@dest + @repository.properties[:name])
      src_abs = File.absolute_path(@repository.path)
  
      if dest_abs == src_abs then
        ## Cannot create the clone in the same place as the original.
        return false
      else
        ## Create a copy of the repository and mark it as a clone in the properties.
        new_repository = Repository.new(dest_abs)
        new_repository.properties[:remote] = src_abs
        new_repository.properties[:clone] = true
        new_repository.properties[:name] = @repository.properties[:name]
        new_repository.save_properties(new_repository.path)

        FileUtils.cp_r(@repository.path,new_repository.path)
        FileUtils.rm(new_repository.path + "/*")
  
        return true
      end
    end #method: execute
  end #class: Add
end #module: Kure





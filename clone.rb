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
        new_repository.properties[:clone]  = true
        new_repository.properties[:name]   = @repository.properties[:name]

        
        FileUtils.cp_r(src_abs,dest_abs)
        FileUtils.rm(Dir.glob(dest_abs + "/*"))

        new_repository.save_properties(new_repository.path)

        new_repository.clear_pending(new_repository.path)
        new_repository.clear_status(new_repository.path)
        new_repository.clear_staging(new_repository.path)
 
        ## TODO: will need to put kure get command here once implemented
 
        return true
      end
    end #method: execute
  end #class: Add
end #module: Kure


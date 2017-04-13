require "digest/md5"
require File.dirname(__FILE__) + '/command.rb'

module Kure
  class Status < Command

    def initialize(repository)
      super(repository)
    end

    def execute()
      @repository.image.each do |k,v|
        unless File.exists?(@repository.path + '/' + k) then
          #TODO: need to go see how I am handling deletes...
          puts "deleted: " + @prepository.path + '/' + k.to_s
        else
          if File.file?(@repository.path + '/' + k) then
            unless File.size(@repository.path + '/' + k) == 
                   File.size("#{@repository.path}/#{@repository.versions_dir}/#{v}/data/" + k) then
              puts "changed: " + @repository.path + '/' + k
            else
              if Digest::MD5.hexdigest(File.read(@repository.path + '/' + k)) !=
                 Digest::MD5.hexdigest(File.read("#{@repository.path}/#{@repository.versions_dir}/#{v}/data/" + k)) then
                puts "changed: " +@repository.path + '/' +  k
              end
            end
          end
        end
      end
      ## check for new files
      #next, get a recursive listing of all files in the working directory
      #and check if they are in the repository. If not, they must be new.
      (Dir["#{@repository.path}/**/*"].reject {|f|File.directory?(f)}).each do |p|
        unless @repository.image.has_key?(p) then
          puts "new: " + p
        end
      end
    end #method: execute
  end #class: Status
end #module: Kure







require File.dirname(__FILE__) + '/command.rb'

module Kure
  class Get < Command

    def initialize(repository,version)
      super(repository)
      @version = version
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

    def execute()
      # TODO: handle bad version number some how...
      # TODO: bandaided this to create dirs if they are missing, but then it
      #       wastes time recopying the same dir again when it gets to it in the list
      image = @repository.load_version(@version,File.absolute_path(@repository.path))
      image.keys.each do |k|
        path = File.absolute_path(@repository.path)
        item = "#{path}/#{@repository.versions_dir}/#{image[k].to_s}/data/#{k}"
        create_missing_dirs(k)
        if File.file?(item) then
          FileUtils.cp(item,"#{path}/#{k}")
        else
          FileUtils.copy_entry(item,"#{path}/#{k}")
        end
      end
    
      #~ items.each do |i|
        #~ item = "#{@repository.versions_dir}/#{image[i]}/data/#{i}"
        #~ create_missing_dirs(item,i)
        #~ if File.file?(item) then
          #~ FileUtils.cp(item,i)
        #~ else
          #~ FileUtils.copy_entry(i)
        #~ end
      #~ end
      
    end #method: execute
  end #class: Get
end #module: Kure

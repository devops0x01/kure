require File.dirname(__FILE__) + '/command.rb'
require File.dirname(__FILE__) + '/log_entry.rb'
require File.dirname(__FILE__) + '/change.rb'

module Kure
  class Log < Command

    def initialize(repository,version)
      super(repository)
      @version = version
    end

    def execute()
      path = File.absolute_path(@repository.path)
      ##TODO: have repository class get the log for us
      return YAML.load(File.read("#{path}/#{@repository.versions_dir}/#{@version}/log"))
    end #method: execute
  end #class: Log
end #module: Kure

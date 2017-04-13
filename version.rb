require File.dirname(__FILE__) + '/command.rb'

module Kure
  class Version < Command

    def initialize(repository)
      super(repository)
    end

    def execute()
        return @repository.last_version
    end

  end


end







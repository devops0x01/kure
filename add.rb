#require "digest/md5"
require File.dirname(__FILE__) + '/change.rb'
require File.dirname(__FILE__) + '/command.rb'

module Kure
  class Add < Command

    def initialize(repository,items)
      super(repository)
      @items = items
    end

    def execute()
      ## Add the indicated items to the repository's pending list
      @items.each do |i|
        if @repository.status.has_key?(i) then
          # TODO: add delete and move to pending here
          c = @repository.status[i]
          @repository.pending[i] = c
          @repository.status.delete(i)
        else
          if File.exists?(@repository.path + "/" + i) then
            c = Change.new
            c.action = "add"
            c.parameters = i
            @repository.pending[i] = c
          else
            return false
          end
        end
      end

      @repository.save_pending(@repository.path)
      @repository.save_status(@repository.path)

    return true
    end #method: execute
  end #class: Add
end #module: Kure





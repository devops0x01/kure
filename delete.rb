require File.dirname(__FILE__) + '/command.rb'

module Kure
  class Delete < Command

    def initialize(repository,items)
      super(repository)
      @items = items
    end

    def add(item)
      @items << item
    end

    def execute()

      @items.each do |i|
        FileUtils.rm(i)
        c = Change.new
        c.action = "delete"
        c.parameters = i
        @repository.status[i] = c
      end
      @repository.save_status(@repository.path)

    end #method: execute
  end #class: Delete
end #module: Kure

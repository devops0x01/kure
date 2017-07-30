require File.dirname(__FILE__) + "/kure.rb"

require File.dirname(__FILE__) + "/create.rb"
require File.dirname(__FILE__) + "/version.rb"
require File.dirname(__FILE__) + "/status.rb"
require File.dirname(__FILE__) + "/add.rb"
require File.dirname(__FILE__) + "/get.rb"
require File.dirname(__FILE__) + "/clone.rb"

include Kure

## program entry point, parses commandline arguments

$kure = KureOrig.new

## note: the code below is temporary. It will be replaced with something more fitting.

## parse the command line arguments
count = 0
while count < ARGV.size do
  if ARGV[count] == "create" then
  ## the command line syntax for this option is as follows:
  ## kure create <name>
  
    #$kure.create(ARGV[count+1])
    c = Create.new(Repository.new(),ARGV[count+1])
    c.execute()

    break
  ## add items to list for future commit
  elsif ARGV[count] == "add" || ARGV[count] == "a" then
    list = Array.new
    count += 1
    while count < ARGV.size do
      list << ARGV[count]
      count += 1
    end
    #$kure.add(list)
    c = Add.new(Repository.new(),list)
    c.execute()

    break
  ## clone a repository subordinate to the original
  ##   first argument is source repository directory
  ##   second argument is destindation directory in 
  ##     which to place the clone
  elsif ARGV[count] == "clone" then
    if ARGV[count+2] then
      #$kure.clone(ARGV[count+1],ARGV[count+2])
      c = Clone.new(Repository.new(ARGV[count+1]),ARGV[count+2])
      c.execute()
    #else
      #$kure.clone(ARGV[count+1])
    end

    break
  ## commit items to the repository
  elsif ARGV[count] == "commit" then
    if ARGV[count+1] then
      $kure.commit(ARGV[count+1])
    else
      $kure.commit
    end
    break
  ## get items from the repository
  elsif ARGV[count] == "get" || ARGV[count] == "g" then
   # $kure.get(ARGV[count+1])
    c = Get.new(Repository.new(),ARGV[count+1])
    c.execute() 
    break
  ## delete items from the repository
  elsif ARGV[count] == "delete" || ARGV[count] == "rm" || ARGV[count] == "del"then
    # TODO: add deletion of multiple items
    $kure.delete([ARGV[count+1]])

    break
  ## move/rename items in the repository
  elsif ARGV[count] == "move" || ARGV[count] == "move" then
    $kure.move(ARGV[count+1],ARGV[count+2])

    break
  ## retreive log information
  elsif ARGV[count] == "log" then
    if ARGV[count+1] then
      log_entry = $kure.get_log(ARGV[count+1])
    else
      log_entry = $kure.get_log()
    end
    puts "Version:   #{log_entry.version}"
    puts "Date_time: #{log_entry.date_time}"
    puts "Message:   #{log_entry.commit_message}"
    puts "File_list: #{log_entry.file_list}"

    break
  ## retreive information about the state of the working directory
  elsif ARGV[count] == "status" || ARGV[count] == "s" then
    puts;puts
    #puts "STATUS:"
    #puts $kure.status
    #puts;puts
    #puts "PENDING:"
    #puts $kure.pending
    #puts;puts
    #$kure.get_status

    c = Status.new(Repository.new('.'))
    c.execute()

    puts;puts
    
	break
  elsif ARGV[count] == "clear" then
    $kure.clear_pending
	
	break
  elsif ARGV[count] == "version" || ARGV[count] == "v" then
    #puts $kure.get_current_version
    c = Version.new(Repository.new('.'))
    puts c.execute()
    puts;puts
  break
  elsif ARGV[count] == "diff" then
    $kure.diff(ARGV[count+1])
  break
  end
  
  count += 1
end






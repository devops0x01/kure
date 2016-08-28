require File.dirname(__FILE__) + "/kure.rb"

## program entry point, parses commandline arguments

$kure = Kure.new

## note: the code below is temporary. It will be replaced with something more fitting.

## parse the command line arguments
count = 0
while count < ARGV.size do
  if ARGV[count] == "create" then
  ## the command line syntax for this option is as follows:
  ## kure create <name>
  
  ## the directory structure for the repository is initialized as follows:
  ##  .kure
  ##    |_file meta data organized by relative path
  ##    |_logged data - commit time, message, diff, file list, cksum, commit id
  ##    |_paths containing the actual file data with versioned names
 

    $kure.create(ARGV[count+1])

    break
  ## add items to list for future commit
  elsif ARGV[count] == "add" || ARGV[count] == "a" then
    list = Array.new
    count += 1
    while count < ARGV.size do
      list << ARGV[count]
      count += 1
    end
    $kure.add(list)

    break
  ## clone a repository subordinate to the original
  elsif ARGV[count] == "clone" then
    $kure.clone(ARGV[count+1])
 
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
    $kure.get(ARGV[count+1])
    
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
    log_entry = $kure.get_log(ARGV[count+1])
    puts "Version: #{log_entry.version}"
    puts "Date_time: #{log_entry.date_time}"
    puts "Commit_message: #{log_entry.commit_message}"
    puts "File_list: #{log_entry.file_list}"

    break
  ## retreive information about the state of the working directory
  elsif ARGV[count] == "status" || ARGV[count] == "s" then
    puts;puts
    puts "STATUS:"
    puts $kure.status
    puts;puts
    puts "PENDING:"
    puts $kure.pending
    puts;puts
    
	break
  elsif ARGV[count] == "clear" then
    $kure.clear_pending
	
	break
  end
  
  count += 1
end






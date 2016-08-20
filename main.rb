## program entry point, parses commandline arguments


## parse the command line arguments
count = 0
while count < ARGV.size do
  
  ## create a repository  
  if ARGV[count] == "create" then
  ## the command line syntax for this option is as follows:
  ## kure create <name>
  
  ## the directory structure for the repository is initialized as follows:
  ##  .kure
  ##    |_file meta data organized by relative path
  ##    |_logged data - commit time, message, diff, file list, cksum, commit id
  ##    |_paths containing the actual file data with versioned names
  
  ## add items to list for future commit
  elsif ARGV[count] == "add" then
  
  ## commit items to the repository
  elsif ARGV[count] == "commit" then
  
  ## get items from the repository
  elsif ARGV[count] == "get" then
  
  ## delete items from the repository
  elsif ARGV[count] == "delete" then

  ## rename an item in the repository
  elsif ARGV[count] == "rename" then
  
  ## move items in the repository
  elsif ARGV[count] == "move" then
  
  ## retreive log information
  elsif ARGV[count] == "log" then
    
  ## retreive information about the state of the working directory
  elsif ARGV[count] == "status" then
  end
  
  count += 1
end

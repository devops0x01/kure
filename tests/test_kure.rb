require "test/unit"
require "./kure.rb"
require "fileutils"


class TestKure < Test::Unit::TestCase
  
  def setup
    @kure = Kure.new()
    @kure.create("test_repo")   
		
		f = File.new("test.txt","w")
    f.puts("a file for testing kure file versioning")
    f.close()
		
		
  end
  
  def teardown
    File.delete("test.txt")
    FileUtils.rm_rf(".kure")
  end
  
  def test_create()
    assert_equal(true,Dir.exists?(".kure"),"check if the repository root directory was created")
		assert_equal(true,File.exists?(".kure/pending"),"check if the pending file was created")
		assert_equal(true,Dir.exists?(".kure/data"),"check if the repository data directory was created")
		assert_equal(true,Dir.exists?(".kure/staged"),"check if the repository staging directory was created")
  end
  
  def test_add()
    assert_equal(true,@kure.add(["test.txt"]))
    assert_equal("test.txt",File.read(".kure/pending").chomp)
		assert_equal(false,@kure.add(["does_not_exist.txt"]))
  end

  def test_commit()
	  assert_equal(true,@kure.add(["test.txt"]))
    assert_equal(true,@kure.commit(),"testing commit method")
		## make sure that the pending file ended up in the repository data directory
		assert_equal(true,File.exists?(".kure/data/test.txt"),"checking that a pending file was committed to the repository")
		## after a commit the pending file should be empty
		assert_equal(0,File.size(".kure/pending"),"checking that the pending file is 0 bytes")
  end
=begin  
  def test_get()
    
  end
  
  def test_delete()
    
  end
  
  def test_move()
    
  end
  
  def test_rename()
    
  end
  
  def test_log()
    
  end
=end
  
end
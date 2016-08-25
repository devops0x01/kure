require "test/unit"
require "./kure.rb"
require "fileutils"


class TestKure < Test::Unit::TestCase
  
  def setup
    @kure = Kure.new()
    @kure.create("test_repo")   
    
    FileUtils.cd("test_repo")
    
    f = File.new("test.txt","w")
    f.puts("a file for testing kure file versioning")
    f.close()

    f = File.new("test1.txt","w")
    f.puts("the second file for testing kure file versioning")
    f.close()

  end
  
  def teardown
    FileUtils.cd ("..")
    FileUtils.rm_rf("test_repo")
  end
  
  def test_create()
    assert_equal(true,Dir.exists?(".kure"),"Check if the repository root directory was created.")
    assert_equal(true,File.exists?(".kure/pending"),"Check if the pending file was created.")
    assert_equal(true,File.exists?(".kure/status"),"Check if the status file was created.")
    assert_equal(true,Dir.exists?(".kure/versions"),"Check if the repository data directory was created.")
    assert_equal(true,Dir.exists?(".kure/staged"),"Check if the repository staging directory was created.")
    assert_equal(true,File.exists?(".kure/properties"),"Check if the properties file was created.")
  end
  
  def test_add()
    assert_equal(true,@kure.add(["test.txt"]),"Test addition of file to the pending commit list.")
    assert_equal("---\ntest.txt: !ruby/object:Change\n  action: add\n  parameters: test.txt",File.read(".kure/pending").chomp,"Test if the pending commit list has accurate information.")
    assert_equal(false,@kure.add(["does_not_exist.txt"]),"Test that an attempt to add a non-existent file does not work.")
  end

  def test_commit()
    @kure.add(["test.txt"])
    assert_equal(true,@kure.commit(),"Testing commit method.")
    assert_equal(true,File.exists?(".kure/versions/0/data/test.txt"),"Checking that the file was committed to the repository.")
    assert_equal("--- {}\n",File.read(".kure/pending"),"Checking that the pending file is an empty hash.")
    
	@kure.add(["test1.txt"])
    @kure.commit()
    assert_equal(true,File.exists?(".kure/versions/1/data/test1.txt"),"Check that version numbers are advancing with new commits.")
    
	f = File.open(".kure/last_version","r")
    last_version = f.read.to_i
    f.close
    assert_equal(1,last_version,"Confirm that our last version number is correct.")
    
	image = YAML.load(File.read(".kure/versions/1/image.yaml"))
    assert_equal(1,image["test1.txt"].to_i,"Checking image file.")
    assert_equal(0,image["test.txt"].to_i,"Checking image file.")

  end
  
=begin   
  def test_get()
    
  end

  def test_log()
    
  end

  def test_clone()

  end
  
  def test_delete()
    
  end
  
  def test_move()
    
  end
  
  def test_rename()
    
  end
  
=end
  
end

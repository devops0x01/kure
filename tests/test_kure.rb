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
    assert_equal(true,Dir.exists?(".kure"),"check if the repository root directory was created")
    assert_equal(true,File.exists?(".kure/pending"),"check if the pending file was created")
    assert_equal(true,Dir.exists?(".kure/versions"),"check if the repository data directory was created")
    assert_equal(true,Dir.exists?(".kure/staged"),"check if the repository staging directory was created")
    assert_equal(true,File.exists?(".kure/properties"),"check if the properties file was created")
    assert_equal(true,File.exists?(".kure/meta"),"check if the meta file was created")
  end
  
  def test_add()
    assert_equal(true,@kure.add(["test.txt"]),"test addition of file to the pending commit list")
    assert_equal("test.txt",File.read(".kure/pending").chomp,"test if the pending commit list has accurate information")
    assert_equal(false,@kure.add(["does_not_exist.txt"]),"test that an attempt to add a non-existent file does not work")
  end

  def test_commit()
    @kure.add(["test.txt"])
    
    assert_equal(true,@kure.commit(),"testing commit method")
    
    ## make sure that the pending file ended up in the repository data directory
    assert_equal(true,File.exists?(".kure/versions/0/data/test.txt"),"checking that a pending file was committed to the repository")
    
    ## after a commit the pending file should be empty
    assert_equal(0,File.size(".kure/pending"),"checking that the pending file is 0 bytes")
    
    ## check that version numbers are advancing with new commits
    @kure.add(["test1.txt"])
    @kure.commit()
    assert_equal(true,File.exists?(".kure/versions/1/data/test1.txt"),"check that version numbers are advancing with new commits")
    
    ## confirm that our last version number is correct
    f = File.open(".kure/last_version","r")
    last_version = f.read.to_i
    f.close
    assert_equal(1,last_version,"confirm that our last version number is correct")
    
    ## test version image files
    image = YAML.load(File.read(".kure/versions/1/image.yaml"))
    assert_equal(1,image["test1.txt"].to_i,"Checking image file.")
    assert_equal(0,image["test.txt"].to_i,"Checking image file.")

  end
=begin  
  def test_clone()

  end

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

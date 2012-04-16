require 'spec_helper'
describe ConnectionManager::Connections do
  # For all tests set the env to "test"
  before(:all) do
    ConnectionManager::Connections.env = "test"
  end
  
  context '#config' do
    it "should work" do
      ConnectionManager::Connections.config(:auto_replicate => true, :env => 'test')
      ConnectionManager::Connections.config[:auto_replicate].should be_true
      ConnectionManager::Connections.config[:env].should eql('test')
    end
  end
  context '#clean_sqlite_db_name' do
    it "should remove the directory .sqlite3, Rails.env from the string" do
      ConnectionManager::Connections.clean_sqlite_db_name("db/my_database_test.sqlite3").should eql("my_database")
    end
  end
  
  context '#clean_db_name' do
    context "when name is not just the Rails.env" do
      it "should remove the Rails.env from the string" do
        ConnectionManager::Connections.clean_db_name("my_database_test").should eql("my_database")
      end
    end
    context "when the name is only the Rails.env" do
      it "should use the name of the database and remove the Rails.env" do
        ConnectionManager::Connections.stubs(:database_name_from_yml).returns("my_database_test")
        ConnectionManager::Connections.clean_db_name("test").should eql("my_database")
      end
      it "should account for sqlite3 database name" do
        ConnectionManager::Connections.stubs(:database_name_from_yml).returns("db/my_database_test.sqlite3")
        ConnectionManager::Connections.clean_db_name("test").should eql("my_database")
      end
    end
  end
  
  context '#connection_class_name' do
    
    it "should return a string for a class name appended with 'Connection' " do
      ConnectionManager::Connections.connection_class_name("my_database").should eql("MyDatabaseConnection")
    end
    it "should return remove the appended rails env" do
      ConnectionManager::Connections.connection_class_name("my_database_test").should eql("MyDatabaseConnection")
    end
#    it "should handle sqlite database names correctly " do
#      ConnectionManager::Connections.connection_class_name("db/my_database_test.sqlite3").should eql("MyDatabaseConnection")
#    end
    it "should use the database name from the database.yml if supplied string is only is only the Rails.env" do
      ConnectionManager::Connections.stubs(:database_name_from_yml).returns("my_test_test")
      ConnectionManager::Connections.connection_class_name("test").should eql("BaseConnection")
    end
  end
    
  context 'after #build_connection_classes' do
    before(:all) do
      #build_connection_classes
      ConnectionManager::Connections.build_connection_classes(:env => 'test')
    end
    
    context '#build_connection_class' do
      before(:all) do
        ConnectionManager::Connections.build_connection_class("MyConnectionClass", 'test')
      end
      it "should add a class with supplied class name to ConnectionManager::Connections" do
        defined?(MyConnectionClass).should be_true
        MyConnectionClass.is_a?(Class).should be_true
      end
      it "should have a super class of ActiveRecord::Base" do
        MyConnectionClass.superclass.should eql(ActiveRecord::Base)
      end
    end   
  end
end


require 'spec_helper'
describe ConnectionManager::Connections do
  # For all tests set the env to "test"
  before(:all) do
    ConnectionManager::Connections.env = "test"
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
    it "should handle sqlite database names correctly " do
      ConnectionManager::Connections.connection_class_name("db/my_database_test.sqlite3").should eql("MyDatabaseConnection")
    end
    it "should use the database name from the database.yml if supplied string is only is only the Rails.env" do
      ConnectionManager::Connections.stubs(:database_name_from_yml).returns("my_test_test")
      ConnectionManager::Connections.connection_class_name("test").should eql("MyTestConnection")
    end
  end
  
   
  context 'after #initialize' do
    before(:all) do
      # Make sure connections recreated in other tests do not presist to tests tests
      ConnectionManager::Connections.all.clear
      ConnectionManager::Connections.secondary_connections.clear
      
      #Initialize
      ConnectionManager::Connections.initialize(:env => 'test')
    end
    
    context '#all' do
      it "should return the database.yml entries for the current rails environment" do
        ConnectionManager::Connections.all.should eql(["CmConnection",
            "Slave1CmConnection", "Slave2CmConnection", "Shard1CmConnection"])
      end
    end
    
    context '#secondary_connections' do
      it "should return a hash where the keys are the generic undescored names for all connections" do
        ConnectionManager::Connections.secondary_connections.keys.
          should eql([:cm, :slave_cm, :shard_cm])
      end
      it "should return a hash where the values are an array of connection class names as strings" do
        first_value = ConnectionManager::Connections.secondary_connections.values.first
        first_value.class.should eql(Array)
        defined?((ConnectionManager::Connections.class_eval(first_value[0]))).should be_true
      end
    end
    
    context '#build_connection_class' do
      before(:all) do
        ConnectionManager::Connections.build_connection_class("MyConnectionClass", 'test')
      end
      it "should add a class with supplied class name to ConnectionManager::Connections" do
        defined?(ConnectionManager::Connections::MyConnectionClass).should be_true
        ConnectionManager::Connections::MyConnectionClass.is_a?(Class).should be_true
      end
      it "should have a super class of ActiveRecord::Base" do
        ConnectionManager::Connections::MyConnectionClass.superclass.should eql(ActiveRecord::Base)
      end
    end   
  end
end


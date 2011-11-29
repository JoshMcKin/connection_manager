require 'spec_helper'
describe ConnectionManager::Connections do
  
  context '#all' do
    it "should return the database.yml entries for the current rails environment" do
      ConnectionManager::Connections.all.should eql(["TestAppConnection", "Slave1TestAppConnection"])
    end
  end
  
  context '#replication_connections' do
    it "should return a hash where the keys are the generic class names for available_connections" do
      ConnectionManager::Connections.replication_connections.keys.
        should eql([:test_test_app, :slave_test_app])
    end
    it "should return a hash where the values are an array of connection class names as strings" do
      first_value = ConnectionManager::Connections.replication_connections.values.first
      first_value.class.should eql(Array)
      defined?((ConnectionManager::Connections.class_eval(first_value[0]))).should be_true
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
      ConnectionManager::Connections.stubs(:database_name_from_yml).returns("MyTest")
      ConnectionManager::Connections.connection_class_name("test").should eql("MyTestConnection")
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


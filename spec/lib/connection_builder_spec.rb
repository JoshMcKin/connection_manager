require 'spec_helper'
describe ConnectionManager::ConnectionBuilder do

  describe '#connection_class_name' do 
    it "should return a string for a class name appended with 'Connection' " do
      ActiveRecord::Base.send(:connection_class_name,"my_database").should eql("MyDatabaseConnection")
    end
    it "should return remove the appended rails env" do
      ActiveRecord::Base.send(:connection_class_name,"my_database_test").should eql("MyDatabaseConnection")
    end
    it "should use the database name from the database.yml if supplied string is only is only the Rails.env" do
      ActiveRecord::Base.send(:connection_class_name,"test").should eql("BaseConnection")
    end
  end
    
  describe '#build_connection_class' do
    before(:all) do
      ActiveRecord::Base.build_connection_class("MyConnectionClass", :test)
    end
    it "should add a class with supplied class name to ConnectionManager::ConnectionBuilder" do
      defined?(MyConnectionClass).should be_true
      MyConnectionClass.is_a?(Class).should be_true
    end
    it "should have a super class of ActiveRecord::Base" do
      MyConnectionClass.superclass.should eql(ActiveRecord::Base)
    end
  end   
end
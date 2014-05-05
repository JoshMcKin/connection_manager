require 'spec_helper'
describe ConnectionManager::Builder do

  describe '#connection_class_name' do 
    it "should return a string for a class name appended with 'Connection' " do
      expect(ConnectionManager::Builder.send(:connection_class_name,"my_database")).to eql("MyDatabaseConnection")
    end
    it "should return remove the appended rails env" do
      expect(ConnectionManager::Builder.send(:connection_class_name,"my_database_test")).to eql("MyDatabaseConnection")
    end
    it "should use the database name from the database.yml if supplied string is only is only the Rails.env" do
      expect(ConnectionManager::Builder.send(:connection_class_name,"test")).to eql("BaseConnection")
    end
  end
    
  describe '#build_connection_class' do
    before(:all) do
      ConnectionManager::Builder.build_connection_class("MyConnectionClass", :test)
    end
    it "should add a class with supplied class name to ConnectionManager::Builder" do
      expect(defined?(MyConnectionClass)).to be_true
      expect(MyConnectionClass).to be_a(Class)
    end
    it "should have a super class of ActiveRecord::Base" do
     expect(MyConnectionClass.superclass).to eql(ActiveRecord::Base)
    end
  end   
end
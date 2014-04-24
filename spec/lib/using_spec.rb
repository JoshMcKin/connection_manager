require 'spec_helper'
class CmFooSlaveConnection < ActiveRecord::Base
  establish_managed_connection(:slave_1_cm_test)
end

describe ConnectionManager::Using do
  
  it "should add sub class to current class with the name of the connection" do
    Fruit.send(:fetch_duplicate_class,"CmFooSlaveConnection")
    lambda { "Fruit::CmFooSlaveConnectionDup".constantize}.should_not raise_error
  end

  describe '#using' do
    it "should return an ActiveRecord::Relation" do
      Fruit.using("CmFooSlaveConnection").should be_kind_of(ActiveRecord::Relation)
    end
    it "should change the connection" do
      Fruit.using("CmFooSlaveConnection").connection.config.should_not eql(Fruit.connection.config)
    end
  
    it "should create the exact same sql if called from model or from relation" do
      class_sql = Fruit.using("CmFooSlaveConnection").where(:name => "malarky").to_sql
      relation_sql = Fruit.where(:name => "malarky").using("CmFooSlaveConnection").to_sql
      class_sql.should eql(relation_sql)
    end
  
    it "should have the same connection if called from model or from relation" do
      Fruit.where(:name => "malarky").using("CmFooSlaveConnection").connection.config.should eql(
        Fruit.using("CmFooSlaveConnection").where(:name => "malarky").connection.config)
      Fruit.using("CmFooSlaveConnection").where(:name => "malarky").connection.config.should_not eql(
        Fruit.where(:name => "malarky").connection.config)
      Fruit.where(:name => "malarky").using("CmFooSlaveConnection").connection.config.should_not eql(
        Fruit.where(:name => "malarky").connection.config)
    end
  end
end
  


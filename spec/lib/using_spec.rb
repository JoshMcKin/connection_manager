require 'spec_helper'
class CmFooSlaveConnection < ActiveRecord::Base
  establish_managed_connection(:slave_1_cm_test)
end
class CmMasterConnection < ActiveRecord::Base
  establish_managed_connection(:master_2_cm_test)
end

describe ConnectionManager::Using do
  
  it "should add sub class to current class with the name of the connection" do
    Fruit.send(:fetch_duplicate_class,"CmFooSlaveConnection")
    lambda { "Fruit::CmFooSlaveConnectionDup".constantize}.should_not raise_error(NameError)
  end

  describe '#using' do
    it "should return an ActiveRecord::Relation" do
      Fruit.using("CmFooSlaveConnection").should be_kind_of(ActiveRecord::Relation)
    end
    it "should change the connection" do
      Fruit.using("CmFooSlaveConnection").connection.config.should_not eql(Fruit.connection.config)
    end
  
    it "should create the exact same sql if called from model or from relation" #do
#      Fruit.where(:name => "malarky").using("CmFooSlaveConnection").to_sql.should eql(
#        Fruit.using("CmFooSlaveConnection").where(:name => "malarky").to_sql)
#    end
  
    it "should have the same connection if called from model or from relation" do
      Fruit.where(:name => "malarky").using("CmFooSlaveConnection").connection.config.should eql(
        Fruit.using("CmFooSlaveConnection").where(:name => "malarky").connection.config)
      Fruit.using("CmFooSlaveConnection").where(:name => "malarky").connection.config.should_not eql(
        Fruit.where(:name => "malarky").connection.config)
      Fruit.where(:name => "malarky").using("CmFooSlaveConnection").connection.config.should_not eql(
        Fruit.where(:name => "malarky").connection.config)
    end
    
    it "should work" do
      FactoryGirl.create(:fruit)
      Fruit.using("CmFooSlaveConnection").first
    end
    
    it "should really use a different connection" do   
      f = Fruit.using("CmMasterConnection").new
      f.name = FactoryGirl.generate(:rand_name)
      f.save
      Fruit.where(:name => "malarky").first.should be_nil
      Fruit.using("CmFooSlaveConnection").where(:name => f.name).first.should be_nil
      Fruit.using("CmMasterConnection").where(:name => f.name).first.should_not be_nil
    end
    
    it "should save to schema/database set in connection class" do
      Fruit.table_name_prefix = "cm_test."
      f = Fruit.using("CmMasterConnection").new
      f.name = FactoryGirl.generate(:rand_name)
      f.save
      Fruit.where(:name => f.name).first.should be_nil
      Fruit.using("CmFooSlaveConnection").where(:name => f.name).first.should be_nil
      Fruit.using("CmMasterConnection").where(:name => f.name).first.should_not be_nil
    end
  end
end
  


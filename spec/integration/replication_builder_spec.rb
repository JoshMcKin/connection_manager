require 'spec_helper'

# Tests for associations build form replication.

describe ConnectionManager::ReplicationBuilder do
  before(:all) do
    # Make sure connections recreated in other tests do not presist to current
    ConnectionManager::Connections.all.clear
    ConnectionManager::Connections.replication_connections.clear
      
    #Initialize
    ConnectionManager::Connections.initialize(:env => 'test')
    
    # Add Replication to models
    Fruit.replicated
    Basket.replicated
    FruitBasket.replicated
    Region.replicated :readonly => false
  end
  
  context "models that have been replicated" do
    it "should respond to slave_1" do
      Fruit.respond_to?(:slave_1).should be_true
    end
    
    it "should respond to slave" do
      Fruit.respond_to?(:slave).should be_true
    end
    
    it "should have a subclass of Slave1" do
      defined?(Fruit::Slave1).should be_true
    end
    
    context "subclasses" do
      it "should have a superclass of the parent class" do
        Fruit::Slave1.superclass.should eql(Fruit)
      end
    end
  end
  
  context "readonly" do
  end
  
  context "slave" do
    context('belongs_to') do
      it "should return the same belongs to object as master" do
        fruit = Factory.create(:fruit)
        
        slave_fruit = Fruit.slave.where(:id => fruit.id).first
        slave_fruit.region.id.should eql(fruit.region.id)
      end
    end
  
    context('has_one') do
      it "should return the same has_on object as master" do
        region = Factory.create(:fruit).region
        slave_region = Region.slave.where(:id => region.id).first
        slave_region.fruit.id.should eql(region.fruit.id)
      end
    end
  
    context('has_many') do
      it "should return the same has_many objects as master" do
        fruit = Factory.create(:fruit)
        3.times do
          Factory.create(:fruit_basket, :fruit_id => fruit.id)
        end
        fruit.fruit_baskets.length.should eql(3)
        slave_fruit = Fruit.slave.where(:id => fruit.id).first     
        slave_fruit.fruit_baskets.length.should eql(fruit.fruit_baskets.length) 
        slave_fruit.fruit_baskets.collect(&:id).should eql(fruit.fruit_baskets.collect(&:id))      
      end
    end
   
    context('has_many :through') do   
      it "should return the same fruit as master" do
        basket = Factory.create(:fruit_basket)
        slave_fruit = Fruit.slave.where(:id => basket.fruit_id).first
        master_fruit = Fruit.where(:id => basket.fruit_id).first   
        slave_fruit.basket_ids.should eql(master_fruit.basket_ids)
      end
    end
    context "readonly" do
     it "should return a readonly object by default" do
       Factory.create(:fruit)
       readonly_fruit = Fruit.slave.first
       readonly_fruit.readonly?.should be_true
       lambda { readonly_fruit.save }.should raise_error
     end
     it "should not return readonly if replicated readonly is to false" do
       Factory.create(:region)
       Region.slave.first.readonly?.should be_false
     end
   end
  end
  context "model_name for slave" do
    it "should return the supers model_name" do
      Fruit.slave.model_name.should eql(Fruit.model_name)
    end
    
    it "should not interfear with inheritance" do
      Factory.create(:fruit)
      class MyFruit < Fruit
        replicated
      end
 
      Fruit.model_name.should_not eql(MyFruit.model_name)
      MyFruit.model_name.should eql("MyFruit")
      MyFruit.model_name.respond_to?(:plural).should be_true
      MyFruit.slave_1.model_name.should eql("MyFruit")
      MyFruit.slave_1.first.class.should eql(MyFruit::Slave1)
      
    end
  end
end


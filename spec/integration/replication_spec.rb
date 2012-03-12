require 'spec_helper'
# Tests for associations build form replication.
describe ConnectionManager::Replication do
  before(:all) do
    # Add Replication to models
    ConnectionManager::Connections.build_connection_classes(:env => 'test')
    Fruit.replicated(:slave_1_cm_test)
    Basket.replicated(:slave_1_cm_test)
    FruitBasket.replicated(:slave_1_cm_test)
    Region.replicated(:slave_2_cm_test)
  end
  
  context "models that have been replicated" do
    it "should respond to slave_1" do
      Fruit.respond_to?(:cm_replication_connection).should be_true
    end
    
    it "should respond to slave" do
      Fruit.respond_to?(:slaves).should be_true
    end
    
    it "should have a subclass with name of the connection class' name with 'Child' appended" do
      defined?(FruitCmReplicationConnectionChild).should be_true
    end
    
    context "subclasses" do
      it "should have a superclass of the parent class" do     
        FruitCmReplicationConnectionChild.superclass.should eql(Fruit)
      end
    end
  end
  
  context "slaves" do
    context('belongs_to') do
      it "should return the same belongs to object as master" do
        fruit = Factory.create(:fruit)      
        slave_fruit = Fruit.slaves.where(:id => fruit.id).first
        slave_fruit.region.id.should eql(fruit.region.id)
      end
    end
  
    context('has_one') do
      it "should return the same has_on object as master" do
        region = Factory.create(:fruit).region
        slave_region = Region.slaves.where(:id => region.id).first
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
        slave_fruit = Fruit.slaves.where(:id => fruit.id).first     
        slave_fruit.fruit_baskets.length.should eql(fruit.fruit_baskets.length) 
        slave_fruit.fruit_baskets.collect(&:id).should eql(fruit.fruit_baskets.collect(&:id))      
      end
    end
   
    context('has_many :through') do   
      it "should return the same fruit as master" do
        basket = Factory.create(:fruit_basket)
        slave_fruit = Fruit.slaves.where(:id => basket.fruit_id).first
        master_fruit = Fruit.where(:id => basket.fruit_id).first   
        slave_fruit.basket_ids.should eql(master_fruit.basket_ids)
      end
    end
    
    context "readonly" do
     it "should return a readonly object by default" do
       Factory.create(:fruit)
       readonly_fruit = Fruit.slaves.first
       readonly_fruit.readonly?.should be_true
       lambda { readonly_fruit.save }.should raise_error
     end
     it "should not return readonly if replicated readonly is to false" do
       Factory.create(:region)
       Region.slaves.first.readonly?.should be_false
     end
   end
  end
  
  context "model_name for slave" do
    it "should return the supers model_name" do
      Fruit.cm_replication_connection.model_name.should eql(Fruit.model_name)
    end
    
    it "should not interfear with inheritance" do
      Factory.create(:fruit)
      class MyFruit < Fruit
        replicated("CmReplicationConnection")
      end
      Fruit.model_name.should_not eql(MyFruit.model_name)
      MyFruit.model_name.should eql("MyFruit")
      MyFruit.model_name.respond_to?(:plural).should be_true
      MyFruit.cm_replication_connection.model_name.should eql("MyFruit")
      MyFruit.cm_replication_connection.first.class.should eql(MyFruitCmReplicationConnectionChild)   
    end
  end
end


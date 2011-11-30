require 'spec_helper'

describe ConnectionManager::ReplicationBuilder do
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
  end
end


require 'spec_helper'

describe FruitBasket do
  context('#slave') do
    it "should return the same fruit as master" do
      @basket = Factory.create(:fruit_basket)
      debugger
      slave_fruit = Fruit.slave.where(:id => @basket.fruit_id).first
      master_fruit = @basket.fruit
      
      slave_fruit.basket_ids.should eql master_fruit.basket_ids
   
   
    end
  end
end


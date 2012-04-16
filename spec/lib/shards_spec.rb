require 'spec_helper'
describe ConnectionManager::Shards do
  before(:each) do
    ConnectionManager::Connections.build_connection_classes(:env => 'test')
    Fruit.shard_class_names("SouthernFruit")            
  end
  context 'shards'do    
    it "should return an array of results" do
      a = Fruit.shards do |shard|
        shard.first
      end
      a.should be_a_kind_of(Array)
    end
    
    it "should execute the active record methods on the the provided models" do
      fruit = FactoryGirl.create(:fruit)
      klasses = ["Fruit","SouthernFruit"]
      a = Fruit.shards do |shard|
        shard.where(:id => fruit.id).first
      end
      klasses.include?(a[0].class.name).should be_true
    end
   
      
    it "should not matter how the where statement is formated" do
      fruit = FactoryGirl.create(:fruit)
      a = Fruit.shards do |shard|
        shard.where(:id => fruit.id).first
      end
      b = Fruit.shards do |shard|
        shard.where(['id = ?', fruit.id]).first
      end
        
      c = Fruit.shards do |shard|
        shard.where('id = ?', fruit.id).first    
      end
        
      (a == b && b == c).should be_true
    end
  end
end
require 'spec_helper'
describe ConnectionManager::Shards do
  before(:each) do
    Fruit.shard_class_names("SouthernFruit")            
  end
  context 'shards'do    
    it "should return an array of results" do
      a = Fruit.shards do |shard|
        shard.first
      end
      expect(a).to be_a(Array)
    end
    
    it "should execute the active record methods on the the provided models" do
      fruit = FactoryGirl.create(:fruit)
      klasses = ["Fruit","SouthernFruit"]
      a = Fruit.shards do |shard|
        shard.where(:id => fruit.id).first
      end
      expect(klasses.include?(a[0].class.name)).to be_true
    end
   
      
    it "should not matter how the where statement is formated" do
      fruit = FactoryGirl.create(:fruit)
      afruit = Fruit.shards do |shard|
        shard.where(:id => fruit.id).first
      end
      
      bfruit = Fruit.shards do |shard|
        shard.where(['id = ?', fruit.id]).first
      end
        
      cfruit = Fruit.shards do |shard|
        shard.where('id = ?', fruit.id).first    
      end
      expect((afruit == bfruit && bfruit == cfruit)).to be_true
    end
  end
end
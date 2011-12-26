require 'spec_helper'

describe ConnectionManager::MethodRecorder do
  before(:each) do
    class Fruit < ActiveRecord::Base
      #include ConnectionManager::MethodRecorder      
      def self.shards
        ConnectionManager::MethodRecorder.new([self])
      end    
    end
  end
  context 'shards'do    
    it "it should record methods" do
      a = Fruit.shards.select('fruits.*').where(:id => 1).order('created_at').first
      a.recordings.should eql({:select => ['fruits.*'], :where => [:id =>1], :order => ['created_at'], :first => []})
    end
    
    context '#execute' do
      it "should return an array of results" do
        a = Fruit.shards.first.execute
        a.should be_a_kind_of(Array)
      end
      it "should execute the active record methods on the the provided class" do
        fruit = Factory.create(:fruit)
        class_to_call = Fruit
        a = class_to_call.shards.where(:id => fruit.id).first.execute
        a[0].should be_a_kind_of(class_to_call)
      end
   
      it "should not matter how the where statement is formated" do
        fruit = Factory.create(:fruit)
        a = Fruit.shards.where(:id => fruit.id).first.execute
        b = Fruit.shards.where(['id = ?', fruit.id]).first.execute
        c = Fruit.shards.where('id = ?', fruit.id).first.execute    
        (a == b && b == c).should be_true
      end
    end
  end
end
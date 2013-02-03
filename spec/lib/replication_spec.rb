require 'spec_helper'
describe ConnectionManager::Replication do
  
  describe '#database_name' do
    it "should return the name of the database the model is using" do
      Fruit.current_database_name.should eql('cm_test')
    end
  end

  describe '#replicated' do
    it "should raise an exception if no connections are empty, and connection.replication_keys are blank" do
      Fruit.connection.stubs(:replication_keys).returns([])
      lambda { Fruit.replicated }.should raise_error
    end
    
    it "should not raise an exception if no connections are empty, but connection.replication_keys are not blank" do
      Fruit.connection.stubs(:replication_keys).returns([:slave_1_cm_test])    
      lambda { Fruit.replicated }.should_not raise_error
    end
    
    context "the methods created from #replicated" do
      it "should create a method with the name given for the :name option" do
        Fruit.replicated(:name => 'foozle')
        Fruit.respond_to?(:foozle).should be_true
      end
      
      it "should create a method in ActiveRecord::QueryMethods with the name given for the :name option" do
        f = FactoryGirl.create(:fruit)
        Fruit.replicated(:name => 'fizzle')
        ActiveRecord::QueryMethods.instance_methods.include?(:fizzle).should be_true
        Fruit.where(:id => f.id).fizzle.first.should_not eql(Fruit.where(:id => f.id).first)
      end
      
      it "should return an ActiveRecord::Relation" do
        Fruit.replicated(:name => 'slaves')
        Fruit.slaves.should be_kind_of(ActiveRecord::Relation)
      end
      
      it "should have a different connection" do
        Fruit.replicated
        Fruit.slaves.connection.config.should_not eql(Fruit.connection.config)
      end
      
      it "should produce the same query string" do
        Fruit.replicated
        Fruit.slaves.joins(:region).to_sql.should eql(Fruit.joins(:region).to_sql)
        Fruit.slaves.joins(:fruit_baskets).to_sql.should eql(Fruit.joins(:fruit_baskets).to_sql)
        Fruit.slaves.includes(:fruit_baskets).to_sql.should eql(Fruit.includes(:fruit_baskets).to_sql)
        Fruit.slaves.includes(:region).to_sql.should eql(Fruit.includes(:region).to_sql)
      end
    end
    
    context "the objects return from a query" do
      # The default connection is the original connection for the model
      it "should have the connection as the replication" do
        Fruit.replicated
        FactoryGirl.create(:fruit)
        Fruit.slaves.first.connection.config.should eql(Fruit.slaves.connection.config)
        Fruit.slaves.first.should_not be_nil
      end    
    end
  end
  
  describe'#replicated?' do
    it "should be false if not replicated" do
      Fruit.replicated?.should be_false
    end
    it "should be true if replicated" do
      Fruit.replicated
      Fruit.replicated?.should be_true
    end
  end
  
    

  #ConnectionManager::Connections.build_connection_classes(:env => 'test')
  class CmFooSlaveConnection < ActiveRecord::Base
    establish_managed_connection(:slave_1_cm_test)
  end
    
  class CmUserConnection < ActiveRecord::Base
    establish_managed_connection(:cm_user_test)
  end
    
  class SlaveCmUserConnection < ActiveRecord::Base
    establish_managed_connection(:slave_1_cm_user_test)
  end
    
  class User < CmUserConnection
    has_many :foos
    has_many(:foo_slaves, :class_name => "Foo::Slaves")
    replicated('SlaveCmUserConnection')
    
  end
    
  class Foo < ActiveRecord::Base
    belongs_to :user
    replicated("CmFooSlaveConnection")
  end
    
  context "eager loading (#includes)" do
    before :each do
      @user = User.new(:name => "Testing")
      @user.save
      @foo = Foo.new(:user_id => @user.id)
      @foo.save
    end
    
    # We'd like this to happen magically some day. Possible in 3.2
    it "should eager load with replication instances" #do
#      user = User.slaves.includes(:foos).where(:id => @user.id).first
#      user.foos.first.should_not be_kind_of(Foo)
#    end
    
    context "specifically defined replication association" do
      it "should eager load with replication instances" do
        user = User.slaves.includes(:foo_slaves).where(:id => @user.id).first
        user.foo_slaves.first.should_not be_kind_of(Foo)
      end
    end   
  end
  context "cross database joins" do   
    before :each do
      @user = User.new(:name => "Testing")
      @user.save
      @foo = Foo.new(:user_id => @user.id)
      @foo.save
    end
    
    it "should work" do
      @user.foos.blank?.should be_false  
      found = Foo.select('users.name AS user_name').joins(:user).where(:id => @foo.id).first
      found.user_name.blank?.should be_false
    end
    
    it "should work with replication" do
      found = Foo.slaves.select('foos.*, users.name AS user_name').joins(:user).where(:id => @foo.id).first
      found.user.blank?.should be_false
    end
  end 
end


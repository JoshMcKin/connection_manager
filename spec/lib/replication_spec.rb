require 'spec_helper'
describe ConnectionManager::Replication do
  
  context '#database_name' do
    it "should return the name of the database the model is using" do
      Fruit.database_name.should eql('cm_test')
    end
  end
  
  context '#replication_class?' do
    it "should be false for Base models" do
      Fruit.replication_class?.should be_false
    end
    it "should be true for child replication classes" do
      Fruit.replicated
      Fruit.slaves.replication_class?.should be_true
    end
  end

  context '#replication_association_options' do
    
    it "should add :class_name options set to the replication subclass if :class_name is blank" do
      options = Fruit.replication_association_options(:has_one, {:replication_class_name => "SlaveFruit"})
      options[:class_name].should eql("SlaveFruit")
    end
    it "should add :readonly => true if replication model is readonly?" do
      Fruit.stubs(:readonly?).returns(true)
      options = Fruit.replication_association_options(:has_one, {:replication_class_name => "SlaveFruit"})
      options[:readonly].should be_true
    end
    context "has_one, has_many and has_and_belongs_to_many" do
      it "should add the :foreign_key if the :foreign_key options is not present" do
        options = Fruit.replication_association_options(:has_one)
        options[:foreign_key].should eql('fruit_id')
        options = Fruit.replication_association_options(:has_many)
        options[:foreign_key].should eql('fruit_id')
      end
    end
  end
  
  context '#build_replication_connections' do
    it "should raise an exception if no connections are empty" do
      lambda { Fruit.build_replication_connections([]) }.should raise_error
    end
  end
  
  context '#replicated' do
    it "should raise an exception if no connections are empty, and connection.replication_keys are blank" do
      Fruit.connection.stubs(:replication_keys).returns([])
      lambda { Fruit.replicated }.should raise_error
    end
    
    it "should not raise an exception if no connections are empty, but connection.replication_keys are not blank" do
      Fruit.connection.stubs(:replication_keys).returns([:slave_1_cm_test])    
      lambda { Fruit.replicated }.should_not raise_error
    end  
  end
  
  context "cross database joins" do
    ConnectionManager::Connections.build_connection_classes(:env => 'test')
    class CmFooSlaveConnection < ActiveRecord::Base
      establish_managed_connection(:slave_1_cm_test)
    end
    
    class CmUserConnection < ActiveRecord::Base
      establish_managed_connection(:cm_user_test)
    end
    
    class SlaveCmUserConnection < ActiveRecord::Base
      establish_managed_connection(:slave_1_cm_user_test)
    end
    
    class Foo < ActiveRecord::Base
      belongs_to :user, :replication_class_name => "UserSlaveCmUserConnectionChild"
      replicated("CmFooSlaveConnection")
    end
    
    class User < CmUserConnection
      has_many :foos
      replicated('SlaveCmUserConnection')
    end
    
    before :all do
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
      found.readonly?.should be_true
      found.user.class.name.should eql("UserSlaveCmUserConnectionChild")
      found.user.readonly?.should be_true
    end
  end 
end


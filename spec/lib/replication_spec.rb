require 'spec_helper'
describe ConnectionManager::Replication do
  
  context '#database_name' do
    it "should return the name of the database the model is using" do
      Fruit.database_name.should eql('cm_test')
    end
  end

  context '#other_association_options' do
    
    it "should add :class_name options set to the replication subclass if :class_name is blank" do
      options = Fruit.replication_association_options(:has_one, :plant, 'Slave')
      options[:class_name].should eql("Plant::Slave")
    end
      
    it "should append :class_name with the replication subclass if :class_name is not bank" do
      options = Fruit.replication_association_options(:has_one, :plant, 'Slave', :class_name => 'Plant')
      options[:class_name].should eql("Plant::Slave")
    end
    
    context "has_one or has_many" do
      it "should add the :foreign_key if the :foreign_key options is not present" do
        options = Fruit.replication_association_options(:has_one, :plant, 'Slave')
        options[:foreign_key].should eql('cm_test.fruit_id')
        options = Fruit.replication_association_options(:has_many, :plant, 'Slave')
        options[:foreign_key].should eql('cm_test.fruit_id')
      end
    end
  end
  
  context '#replicated' do
    it "should raise an exception if no replication_connection_classes are found" do
      Fruit.stubs(:secondary_connection_classes).returns([])
      lambda { Fruit.replicated }.should raise_error
    end
    
  end
  
  context "cross database joins" do
    ConnectionManager::Connections.build_connection_classes(:env => 'test')
    class CmUserConnection < ActiveRecord::Base
      establish_managed_connection(:cm_user_test)
    end
    
    class SlaveCmUserConnection < ActiveRecord::Base
      establish_managed_connection(:slave_1_cm_user_test)
    end
    
    class Foo < ActiveRecord::Base
      belongs_to :user 
      replicated(:slave_1_cm_test)
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
      puts Foo.select('users.name AS user_name').joins(:user).where(:id => @foo.id).to_sql
      found.user_name.blank?.should be_false
    end
    
    it "should work with replication" do
      found = Foo.slaves.select('users.name AS user_name').joins(:user).where(:id => @foo.id).first
      puts Foo.slaves.select('users.name AS user_name').joins(:user).where(:id => @foo.id).to_sql

      found.user_name.blank?.should be_false

    end
  end 
end


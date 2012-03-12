require 'spec_helper'
describe ConnectionManager::ConnectionHelpers do
  before(:all) do
    
    class MyConnectionClass < ActiveRecord::Base
      establish_managed_connection(:test)
    end
    
    class MyReadonlyConnectionClass < ActiveRecord::Base
      establish_managed_connection({
          :database => "cm_test",
          :adapter => "mysql2",
          :username => TestDB.yml("mysql2")["test"]["username"],
          :password => TestDB.yml("mysql2")["test"]["password"]

        }, {:readonly => true})
    end
    
    class MyFoo < MyConnectionClass
      self.table_name = 'foos'
    end
    
    class MyReadonlyFoo < MyReadonlyConnectionClass
      self.table_name = 'foos'
    end
  end
  context '#establish_managed_connection' do
    context 'the connection class' do
    
      it "should create abstract class" do
        MyConnectionClass.abstract_class.should be_true
      end
  
      it "should prefix table name with database" do
        MyConnectionClass.table_name_prefix.should eql('cm_test.')
      end
      
      it "should checkin the connection" do
        ActiveRecord::Base.managed_connection_classes.include?("MyConnectionClass").should be_true
        ActiveRecord::Base.managed_connection_classes.include?("MyReadonlyConnectionClass").should be_true
      end
    end
    context 'the model' do
      it "should not be readonly" do
        u = MyFoo.new
        u.readonly?.should_not be_true
      end
      it "should be readonly if readonly option for establish_managed_connection from connaction class is true" do
        u = MyReadonlyFoo.new
        u.readonly?.should be_true
      end
    end
  end
end


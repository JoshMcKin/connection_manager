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
  describe '#establish_managed_connection' do
    context 'the connection class' do
    
      it "should create abstract class" do
        MyConnectionClass.abstract_class.should be_true
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
  
  describe '#use_database' do
    it "should set the database/schema for the model to the supplied schema_name" do
      Fruit.use_database('my_schema')
      Fruit.current_database_name.should eql('my_schema')
    end
  
    it "should set the contactinate the schema_name and table_name; and set the table_name to that value" do
      Fruit.use_database('my_schema')
      Fruit.table_name.should eql('my_schema.fruits')
      Fruit.table_name_prefix.should eql('my_schema.')
    end
  
    it "should set the table_name if one is supplied" do
      Fruit.use_database('my_schema',{:table_name => 'apples'})
      Fruit.table_name.should eql('my_schema.apples')
      Fruit.table_name_prefix.should eql('my_schema.')
    end
  end
end


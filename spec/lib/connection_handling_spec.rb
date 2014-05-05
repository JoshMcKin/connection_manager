require 'spec_helper'
describe ConnectionManager::ConnectionHandling do
  before(:all) do
 
    class MyConnectionClass < ActiveRecord::Base
      establish_managed_connection(:test)
    end
    
    class MyReadonlyConnectionClass < ActiveRecord::Base
      establish_managed_connection({
          :database => "cm_test",
          :adapter => "mysql2",
          :username => TestDB.yml["test"]["username"],
          :password => TestDB.yml["test"]["password"]

        })
    end
    
    class MyPrefixedConnection < MyConnectionClass
      self.abstract_class = true
      self.use_database("boo")
    end
    
    class MyFoo < MyConnectionClass
      self.table_name = 'foos'
    end

  end
  describe '#establish_managed_connection' do
    context 'the connection class' do
    
      it "should create abstract class" do
        expect(MyConnectionClass.abstract_class).to be_true
      end
      
      it "should check in the connection" do
        expect(ActiveRecord::Base.managed_connection_classes.include?("MyConnectionClass")).to be_true
        expect(ActiveRecord::Base.managed_connection_classes.include?("MyReadonlyConnectionClass")).to be_true
      end
    end
  end
  
  describe '#use_database' do
    it "should set the database/schema for the model to the supplied schema_name" do
      Fruit.use_database('my_schema')
      expect(Fruit.arel_table.name).to eql('my_schema.fruits')
    end
  
    it "should concatenate the schema_name and table_name; and set the table_name to that value" do
      Fruit.use_database('my_schema')
      expect(Fruit.table_name).to eql('my_schema.fruits')
      expect(Fruit.table_name_prefix).to eql('my_schema.')
    end
  
    it "should set the table_name if one is supplied" do
      Fruit.use_database('my_schema',{:table_name => 'apples'})
      expect(Fruit.table_name).to eql('my_schema.apples')
      expect(Fruit.table_name_prefix).to eql('my_schema.')
    end

    it "should get database from connection.config if table name prefix is not set and adapter is mysql" do
      expect(Fruit.connection.mysql?).to be_true
      Fruit.table_name_prefix = nil
      Fruit.table_name = 'fruit'
      expect(Fruit.table_name).to eql('fruit')
      expect(Fruit.table_name_prefix).to be_nil
      Fruit.use_schema
      expect(Fruit.table_name_prefix).to eql("cm_test.")
      expect(Fruit.table_name).to eql('cm_test.fruit')
    end
  end
end


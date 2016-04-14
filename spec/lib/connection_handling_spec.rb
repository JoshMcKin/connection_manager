require 'spec_helper'
describe ConnectionManager::ConnectionHandling do
  before(:all) do

    class MyConnectionClass < ActiveRecord::Base
      self.abstract_class = true
      establish_connection({
                             :database => "cm_test",
                             :adapter => "mysql2",
                             :username => TestDB.yml["test"]["username"],
                             :password => TestDB.yml["test"]["password"]

      })
    end

    class MyManagedConnectionClass < ActiveRecord::Base
      establish_managed_connection(:test, :schema_name => 'yep')
    end

    class MySchemaNameConnection < MyManagedConnectionClass
      self.abstract_class = true
      self.schema_name = "boo"
    end

    class Booed < MySchemaNameConnection;end

    class MyFoo < MyManagedConnectionClass
      self.table_name = 'foo'
      self.schema_name = 'boo'
    end
  end

  describe '#schema_name=' do
    it "should set the table_name_prefix for a table formatted as a schema" do
      expect(MyFoo.table_name_prefix).to eql('boo.')
    end
    it "should set the table_name using schema" do
      expect(MyFoo.table_name).to eql('boo.foo')
    end

    it "should be inherited" do
      expect(Booed.schema_name).to eql(MySchemaNameConnection.schema_name)
      expect(Booed.schema_name).to eql('boo')
      expect(Booed.table_name_prefix).to eql(MySchemaNameConnection.table_name_prefix)
    end
  end

  describe '#establish_connection' do
    it "should register class as connection class" do
      expect(ActiveRecord::Base.managed_connection_classes.include?("MyConnectionClass")).to eql(true)
    end
  end

  describe '#establish_managed_connection' do
    context 'the connection class' do
      it "should create abstract class" do
        expect(MyManagedConnectionClass.abstract_class).to eql(true)
      end

      it "should check in the connection" do
        expect(ActiveRecord::Base.managed_connection_classes.include?("MyManagedConnectionClass")).to eql(true)
      end
    end
  end
end

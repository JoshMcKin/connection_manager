require 'spec_helper'
describe ActiveRecord::ConnectionAdapters::Mysql2Adapter do
  describe '#fetch_full_table_name' do
    it "should return a string consisting of the schema name, a '.' and the table_name" do
      Fruit.connection.fetch_full_table_name('fruits').should eql('cm_test.fruits')
    end
  end

  describe '#table_exists?' do
    it "should return true for unquoted full_names" do
      Fruit.connection.table_exists?('cm_test.fruits').should be_true
    end
     it "should return true for table only names" do
      Fruit.connection.table_exists?('fruits').should be_true
    end
  end
end
describe ActiveRecord::Base do
  describe '#arel_table' do
    it "should use quote_table_name" do
      Fruit.arel_table.name.should eql('cm_test.fruits')
    end
  end
end

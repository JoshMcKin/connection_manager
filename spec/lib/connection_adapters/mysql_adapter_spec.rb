require 'spec_helper'

# Really an integration/regression test will move once we drop support for <= 3.1
describe  ActiveRecord::Base do
  describe '#table_exists?' do
    it "should return true for unquoted full_names" do
      expect(Fruit.connection.table_exists?('cm_test.fruits')).to be_true
    end
    it "should return true for table only names" do
      expect(Fruit.connection.table_exists?('fruits')).to be_true
    end
  end
end

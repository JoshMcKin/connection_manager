require 'spec_helper'
describe ConnectionManager::Core do
  describe 'Arel::Table.name' do
    it "should update as model's table_name update " do
      expect(FruitCore.arel_table.name).to eql('fruits')
      FruitCore.table_name = 'cm_test.fruits'
     expect(FruitCore.arel_table.name).to eql('cm_test.fruits')
    end
  end
end

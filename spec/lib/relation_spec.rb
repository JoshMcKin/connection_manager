require 'spec_helper'
describe ConnectionManager::Relation  do
  context 'ActiveRecord::Relation' do
    describe '#using' do
      it "should be defined" do
        expect(Fruit.where(:id => 1)).to respond_to(:using)
      end
    end
    describe '#slaves' do
      it "should be defined" do
        expect(Fruit.where(:id => 1)).to respond_to(:slaves)
      end
    end

    describe '#masters' do
      it "should be defined" do
        expect(Fruit.where(:id => 1)).to respond_to(:masters)
      end
    end
  end
end

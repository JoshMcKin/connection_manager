require 'spec_helper'
describe ConnectionManager::Querying  do
  describe '#using' do
    it "should be defined" do
      expect(Fruit).to respond_to(:using)
    end
  end
  describe '#slaves' do
    it "should be defined" do
      expect(Fruit).to respond_to(:slaves)
    end
  end

  describe '#masters' do
    it "should be defined" do
      expect(Fruit).to respond_to(:masters)
    end
  end
end

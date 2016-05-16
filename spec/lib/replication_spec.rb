require 'spec_helper'
describe ConnectionManager::Replication do

  describe '#arel_table' do
    it "should return the name of the database the model is using" do
      expect(Fruit.arel_table.name).to eql('cm_test.fruits')
    end
  end

  describe '#replicated' do
    it "should raise an exception if no connections are empty, and connection.replication_keys are blank" do
      ActiveRecord::Base.stubs(:replication_connections).returns({:masters => [], :slaves => []})
      ActiveRecord::ConnectionAdapters::AbstractAdapter.any_instance.stubs(:slave_keys).returns([])
      ActiveRecord::ConnectionAdapters::AbstractAdapter.any_instance.stubs(:master_keys).returns([])
      expect(lambda { Fruit.replicated }).to raise_error(ArgumentError)
    end

    it "should not raise an exception if no connections are empty, but connection.replication_keys are not blank" do
      Fruit.connection.stubs(:replication_keys).returns([:slave_1_cm_test])
      expect(lambda { Fruit.replicated }).to_not raise_error
    end

    context "the objects return from a query" do
      it "should not have the same connection as the master class" do
        Fruit.replicated
        FactoryGirl.create(:fruit)
        expect(Fruit.slaves.connection.config).to_not eql(Fruit.connection.config)
        expect(Fruit.slaves.first).to_not be_nil
      end
    end
  end

  describe'#replicated?' do
    it "should be false if not replicated" do
      expect(Fruit).to_not be_replicated
    end
    it "should be true if replicated" do
      Fruit.replicated
      expect(Fruit).to be_replicated
    end
  end

  it "should produce the same SQL string" do
    Fruit.replicated
    expect(Fruit.slaves.joins(:region).to_sql).to eql(Fruit.joins(:region).to_sql)
    expect(Fruit.slaves.joins(:fruit_baskets).to_sql).to eql(Fruit.joins(:fruit_baskets).to_sql)
    expect(Fruit.slaves.includes(:fruit_baskets).to_sql).to eql(Fruit.includes(:fruit_baskets).to_sql)
    expect(Fruit.slaves.includes(:region).to_sql).to eql(Fruit.includes(:region).to_sql)
  end
end

require 'spec_helper'
class CmFooSlaveConnection < ActiveRecord::Base
  establish_connection(:slave_test)
end

describe ConnectionManager::Using do
  describe '#using' do
    it "should return an ActiveRecord::Relation" do
      expect(Fruit.using("CmFooSlaveConnection")).to be_kind_of(ActiveRecord::Relation)
    end
    it "should change the connection" do
      expect(Fruit.using("CmFooSlaveConnection").connection.config).to_not eql(Fruit.connection.config)
    end

    it "should create the exact same sql if called from model or from relation" do
      class_sql = Fruit.using("CmFooSlaveConnection").where(:name => "malarky").to_sql
      relation_sql = Fruit.where(:name => "malarky").using("CmFooSlaveConnection").to_sql
      expect(class_sql).to eql(relation_sql)
    end

    it "should have the same connection if called from model or from relation" do
      expect(Fruit.where(:name => "malarky").using("CmFooSlaveConnection").connection.
        config).to eql(Fruit.using("CmFooSlaveConnection").where(:name => "malarky").connection.config)
      expect(Fruit.using("CmFooSlaveConnection").where(:name => "malarky").connection.
        config).to_not eql(Fruit.where(:name => "malarky").connection.config)
      expect(Fruit.where(:name => "malarky").using("CmFooSlaveConnection").connection.
        config).to_not eql(Fruit.where(:name => "malarky").connection.config)
    end

    context "A replication like connection" do
      it "should return same record" do
        fruit = FactoryGirl.create(:fruit)
        expect(Fruit.using("CmFooSlaveConnection").where(:id => fruit.id).first).to eql(fruit)
      end
    end

    context 'A shard like connection' do
      it "should use other connection" do
        fruit = FactoryGirl.create(:fruit)
        expect(Fruit.using("OtherConnection").where(:name => fruit.name).exists?).to be_false
      end
    end
  end
end

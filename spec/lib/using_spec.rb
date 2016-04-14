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

      it "should work" do
        fb = FactoryGirl.create(:fruit_basket)
        expect(lambda {FruitBasket.using("CmFooSlaveConnection").
                       joins(:fruit,:basket).includes(:fruit,:basket).where(:id => fb.id).first}).to_not raise_error
      end
    end

    context 'A shard like connection' do
      it "should use other connection" do
        fruit = FactoryGirl.create(:fruit)
        expect(Fruit.using("OtherConnection").where(:name => fruit.name).exists?).to eql(false)
      end
    end

    context "`klass` comparators should work" do
      context "Proxy to non proxy" do
        it "should work" do
          expect(lambda { Fruit.using("OtherConnection").klass >=  Fruit.where(:id => 1).klass}).to_not raise_error
        end
      end
      context "non-proxy to proxy" do
        it "should work" do
          expect(lambda { Fruit.where(:id => 1).klass >= Fruit.using("OtherConnection").klass}).to_not raise_error
        end
      end
    end
  end
end

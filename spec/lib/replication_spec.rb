require 'spec_helper'
describe ConnectionManager::Replication do

  describe '#database_name' do
    it "should return the name of the database the model is using" do
      Fruit.current_database_name.should eql('cm_test')
    end
  end

  describe '#replicated' do
    it "should raise an exception if no connections are empty, and connection.replication_keys are blank" do
      Fruit.connection.stubs(:replication_keys).returns([])
      lambda { Fruit.replicated }.should raise_error
    end

    it "should not raise an exception if no connections are empty, but connection.replication_keys are not blank" do
      Fruit.connection.stubs(:replication_keys).returns([:slave_1_cm_test])
      lambda { Fruit.replicated }.should_not raise_error
    end

    context "the methods created from #replicated" do
      it "should create a method with the name given for the :name option" do
        Fruit.replicated(:name => 'foozle')
        Fruit.respond_to?(:foozle).should be_true
      end

      it "should create a method in ActiveRecord::QueryMethods with the name given for the :name option" do
        f = FactoryGirl.create(:fruit)
        Fruit.replicated(:name => 'fizzle')
        ActiveRecord::QueryMethods.instance_methods.include?(:fizzle).should be_true
      end

      it "should return an ActiveRecord::Relation" do
        Fruit.replicated(:name => 'slaves')
        Fruit.slaves.should be_kind_of(ActiveRecord::Relation)
      end

      it "should have a different connection" do
        Fruit.replicated
        Fruit.slaves.connection.config.should_not eql(Fruit.connection.config)
      end

      it "should work" do
        Fruit.replicated
        Fruit.slaves.joins(:region).joins("LEFT OUTER JOIN `fruit_baskets` ON `fruit_baskets`.`fruit_id` = `cm_test`.`fruits`.`id`").to_sql.should eql(Fruit.joins(:region).joins("LEFT OUTER JOIN `fruit_baskets` ON `fruit_baskets`.`fruit_id` = `cm_test`.`fruits`.`id`").to_sql)
      end

      it "should produce the same query string" do
        Fruit.replicated
        Fruit.slaves.joins(:region).to_sql.should eql(Fruit.joins(:region).to_sql)
        Fruit.slaves.joins(:fruit_baskets).to_sql.should eql(Fruit.joins(:fruit_baskets).to_sql)
        Fruit.slaves.includes(:fruit_baskets).to_sql.should eql(Fruit.includes(:fruit_baskets).to_sql)
        Fruit.slaves.includes(:region).to_sql.should eql(Fruit.includes(:region).to_sql)
      end

      context '#slaves' do
        it "should have the same quoted_table_name" do
          Fruit.replicated

          Fruit.slaves.quoted_table_name.should eql(Fruit.quoted_table_name)
        end
        it "should have the same table_name_prefix"do
          Fruit.replicated
          Fruit.slaves.table_name_prefix.should eql(Fruit.table_name_prefix)
        end
      end
    end

    context "the objects return from a query" do
      it "should not have the same connection as the master class" do
        Fruit.replicated
        FactoryGirl.create(:fruit)
        Fruit.slaves.connection.config.should_not eql(Fruit.connection.config)
        Fruit.slaves.first.should_not be_nil
      end
    end
  end

  describe'#replicated?' do
    it "should be false if not replicated" do
      Fruit.replicated?.should be_false
    end
    it "should be true if replicated" do
      Fruit.replicated
      Fruit.replicated?.should be_true
    end
  end
end

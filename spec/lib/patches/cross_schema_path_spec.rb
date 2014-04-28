require 'spec_helper'
describe  ActiveRecord::ConnectionAdapters::AbstractAdapter do

  describe '#fetch_table_schema' do
    context "table is unique in DMS" do
      it "should return a string consisting of the schema name, a '.' and the table_name" do
        Fruit.connection.fetch_table_schema('fruits').should eql('cm_test')
      end
    end

    context "table is not unique in DMS" do
      it "should return a string consisting of the schema name, a '.' and the table_name" do
        Fruit.connection.fetch_table_schema('type').should eql(nil)
      end
    end
  end

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

  context "Cross Schema Joins" do
    before :each do
      @user = CmUser.new(:name => "Testing")
      @user.save
      @foo = Foo.new(:cm_user_id => @user.id)
      @foo.save
    end

    describe '#joins' do
      it "should work" do
        @user.foos.blank?.should be_false
        found = Foo.joins(:cm_user).select('cm_users.name AS user_name').where('cm_users.id = ?',@user.id).first
        found.user_name.blank?.should be_false
      end
    end
    describe '#includes' do
      before(:each) do
        @user.foos.blank?.should be_false
        search = Foo.includes(:cm_user).where('cm_users.id = ?',@user.id)
        search = search.references(:cm_user) if search.respond_to?(:references)
        @found = search.first
      end
      it "should return a results" do
        @found.should be_a(Foo) # Make sure results are returns
      end
      it "should loan associations" do
        if @found.respond_to?(:association)
          @found.association(:cm_user).loaded?.should be_true
        else
          @found.cm_user.loaded?.should be_true
        end
      end
    end
  end
end

require 'spec_helper'
describe ConnectionManager::AbstractAdapter do
  before(:each) do
    @con = ActiveRecord::ConnectionAdapters::AbstractAdapter.new(nil) # not testing connection so use nil it get an instance
  end

  describe '#config' do
    it {expect(@con).to respond_to(:config)}
  end

  describe '#cross_schema_support?' do
    it "should be true for Mysql" do
      @con.stubs(:config).returns({:adapter => 'mysql'})
      expect(@con.cross_schema_support?).to be_true
    end
    it "should be true for Postgres" do
      @con.stubs(:config).returns({:adapter => 'postgresql'})
      expect(@con.cross_schema_support?).to be_true
    end
    it "should be true for SQL server" do
      @con.stubs(:config).returns({:adapter => 'sqlserver'})
      expect(@con.cross_schema_support?).to be_true
    end
  end

  describe '#readonly?' do
    it "should be true if readonly is set in config" do
      @con.stubs(:config).returns({:readonly => true})
      expect(@con.readonly?).to be_true
    end
    it "should be false if readonly is not set in config" do
      @con.stubs(:config).returns({})
      expect(@con.readonly?).to be_false
    end
  end

  describe '#slave_keys' do
    it "should return slaves from config symbolized" do
      @con.stubs(:config).returns({:slaves => ['test','foo']})
      expect(@con.slave_keys).to eql([:test,:foo])
    end
  end

  describe '#master_keys' do
    it "should return slaves from config symbolized" do
      @con.stubs(:config).returns({:masters => ['bar','baz']})
      expect(@con.master_keys).to eql([:bar,:baz])
    end
  end

  describe '#replications' do
    it "should return all slaves and master keys set in config" do
      @con.stubs(:config).returns({:slaves => [:test,:foo],
                                  :masters => [:bar,:baz]})
      expect(@con.replications).to eql({:slaves => [:test,:foo],
                                   :masters => [:bar,:baz]})
    end
  end
end

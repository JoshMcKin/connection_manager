require 'spec_helper'
describe ConnectionManager::Using::Proxy do
  before(:each) do
    @proxy =  ConnectionManager::Using::Proxy.new(Fruit, OtherConnection)
  end

  describe '#connection' do
    it 'returns connection from connection_class' do
      expect(@proxy.connection.config).to eql(OtherConnection.connection.config)
    end
  end
  describe '#superclass' do
    it "should return the @klass's superclass" do
      expect(@proxy.superclass).to eql(Fruit.superclass)
    end
  end
  describe '#method_missing' do
    it "should direct to @klass" do
      expect(@proxy.table_name).to eql(Fruit.table_name)
    end
  end
  describe '#responds_to?' do
  	it "should direct to @klass" do
  		expect(@proxy).to respond_to(:where)
  	end
  end
end

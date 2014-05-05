require 'spec_helper'
describe ActiveRecord::Base do
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
      expect(found.user_name).to_not be_blank
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
      expect(@found).to be_a(Foo) # Make sure results are returns
    end
    it "should load associations" do
      if @found.respond_to?(:association)
        expect(@found.association(:cm_user)).to be_loaded
      else
        expect(@found.cm_user).to be_loaded
      end
    end
  end
end

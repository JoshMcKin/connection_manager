require 'spec_helper'
class AsFoo < ActiveRecord::Base
  belongs_to :that
  has_many :foo_bars
  has_many :as_bars, :through => :foo_bars
  has_one :noob
end

class AsBar < ActiveRecord::Base
  has_many :foo_bars
  has_many :as_foos, :through => :foo_bars
end

describe ConnectionManager::Associations do
  
  it "should add associations as keys to @defined_associations" do
    AsFoo.defined_associations.keys.should eql([:belongs_to,:has_many,:has_one]) 
    AsBar.defined_associations.keys.should eql([:has_many])
  end
  
  context "defined_association values" do
    it "should be an array of association options (which are Arrays as well)" do
      AsFoo.defined_associations[:belongs_to].should eql([[:that]])
      AsFoo.defined_associations[:has_many].should eql([[:foo_bars],[:as_bars, {:through=>:foo_bars, :extend=>[]}]]) # when options are present active_record addes the :extend option defaulted to []
      AsFoo.defined_associations[:has_one].should eql([[:noob]])
    end
  end
  
end


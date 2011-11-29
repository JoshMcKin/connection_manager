class Fruit < ActiveRecord::Base
  belongs_to :region
  has_many :fruit_baskets
  has_many :baskets, :through => :fruit_baskets
  replicated
end

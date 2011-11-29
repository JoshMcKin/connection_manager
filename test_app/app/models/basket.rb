class Basket < ActiveRecord::Base
  has_many :fruit_baskets
  has_many :fruit, :through => :fruit_baskets
end

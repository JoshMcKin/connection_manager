class CmConnection < ActiveRecord::Base
  establish_managed_connection(:test)
end

class CmReplicationConnection < ActiveRecord::Base
  establish_managed_connection(:slave_1_cm_test)
end

class Basket < CmConnection
  has_many :fruit_baskets
  has_many :fruit, :through => :fruit_baskets
  #replicated
end

class Fruit < CmConnection
  belongs_to :region
  has_many :fruit_baskets
  has_many :baskets, :through => :fruit_baskets
  #replicated
end

#Join table
class FruitBasket < CmConnection
  belongs_to :fruit
  belongs_to :basket
  #replicated
end

class Region < CmConnection
  has_one :fruit
  #replicated
end

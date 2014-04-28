class CmReplicationConnection < ActiveRecord::Base
  establish_managed_connection(:slave_1_cm_test)
end

class CmReplication2Connection < ActiveRecord::Base
  establish_managed_connection(:slave_2_cm_test)
end

class Basket < ActiveRecord::Base
  has_many :fruit_baskets
  has_many :fruit, :through => :fruit_baskets
  #replicated
end

class Fruit < ActiveRecord::Base
  belongs_to :region
  has_many :fruit_baskets
  has_many :baskets, :through => :fruit_baskets
  #replicated
end

#Join table
class FruitBasket < ActiveRecord::Base
  belongs_to :fruit
  belongs_to :basket
  #replicated
end

class Region < ActiveRecord::Base
  has_one :fruit
  #replicated
end

class Type < ActiveRecord::Base;end

class SouthernFruit < Fruit
  self.table_name = 'fruits'
end

class CmUser < ActiveRecord::Base
  has_many :foos
end

class Foo < ActiveRecord::Base
  belongs_to :cm_user
end

class ModelsHelper
  def self.models
    ["Basket", "Fruit", "FruitBasket", "Region","SouthernFruit", "Type", "Foo", "CmUser"]
  end
end

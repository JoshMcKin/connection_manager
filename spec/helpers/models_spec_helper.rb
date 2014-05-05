class CmReplicationConnection < ActiveRecord::Base
  establish_connection(:test_other)
end

class OtherConnection < ActiveRecord::Base
  establish_connection(:test_other)
end

class Basket < ActiveRecord::Base
  has_many :fruit_baskets
  has_many :fruit, :through => :fruit_baskets
end

class PgFruit < OtherConnection
  self.table_name = "cm_test.fruits"
end

class Fruit < ActiveRecord::Base
  self.table_name_prefix = 'cm_test.'
  belongs_to :region
  has_many :fruit_baskets
  has_many :baskets, :through => :fruit_baskets
end

#Join table
class FruitBasket < ActiveRecord::Base
  belongs_to :fruit
  belongs_to :basket
end

class Region < ActiveRecord::Base
  has_one :fruit
end

class Type < ActiveRecord::Base;end

class CmUser < ActiveRecord::Base
  self.table_name_prefix = 'cm_user_test.'
  has_many :foos
end

class CmOtherUser < ActiveRecord::Base
  self.table_name = 'cm_user_test.cm_users'
end

class Foo < ActiveRecord::Base
  belongs_to :cm_user
end

# Subclassed
class SouthernFruit < Fruit
  self.table_name = 'fruits'
end

class FruitCore < Fruit
  self.table_name = 'fruits'
end

class ModelsHelper
  def self.models
    ["Basket", "Fruit", "FruitBasket", "Region","SouthernFruit", "Type", "Foo", "CmUser", "FruitCore"]
  end
end

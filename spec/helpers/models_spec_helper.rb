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


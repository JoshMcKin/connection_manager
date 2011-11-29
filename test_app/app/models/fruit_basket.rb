class FruitBasket < ActiveRecord::Base
  belongs_to :fruit
  belongs_to :basket
  replicated
end

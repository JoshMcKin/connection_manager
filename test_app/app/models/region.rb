class Region < ActiveRecord::Base
  has_one :fruit
  replicated
end

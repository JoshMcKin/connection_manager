class Region < ActiveRecord::Base
  has_many :fruit
  replicated
end

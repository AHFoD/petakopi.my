class Tag < ApplicationRecord
  has_many :coffee_shop_tags
  has_many :coffee_shops, through: :coffee_shop_tags
end

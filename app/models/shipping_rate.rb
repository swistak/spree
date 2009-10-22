class ShippingRate < ActiveRecord::Base
  belongs_to :shipping_method
  belongs_to :shipping_category
  
  has_calculator

  def name
    "#{shipping_method && shipping_method.name} - #{shipping_category && shipping_category.name}"
  end
end

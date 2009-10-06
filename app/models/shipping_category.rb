class ShippingCategory < ActiveRecord::Base
  has_many :shipping_rates, :dependant => :destroy

  validates_presence_of :name
end

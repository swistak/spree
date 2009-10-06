class ShippingCategory < ActiveRecord::Base
  has_many :shipping_rates, :dependent => :destroy

  validates_presence_of :name
end

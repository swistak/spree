class ShippingMethod < ActiveRecord::Base
  belongs_to :zone
  has_many :shipping_rates, :dependent => :destroy
  has_many :shipments

  validates_length_of :name, :minimum => 2

  has_calculator
   
  def calculate_cost(shipment)
    rate_calculators = {}
    shipping_rates.each do |sr|
      rate_calculators[sr.shipping_category_id] = sr.calculator
    end
 
    calculated_costs = shipment.order.line_items.group_by{|li|
      li.product.shipping_category_id
    }.map{ |shipping_category_id, line_items|
      calc = rate_calculators[shipping_category_id] || self.calculator
      calc.compute(line_items)
    }.sum
 
    return(calculated_costs)
  end   
  
  def available?(order)
    zone.include?(order.shipment.address) &&
      calculator
  end
end

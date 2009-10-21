class Calculator::FlatPercentItemTotal < Calculator
  preference :flat_percent, :decimal, :default => 0

  def self.description
    I18n.t("flat_percent")
  end

  def self.register
    super                                
    Coupon.register_calculator(self)
    ShippingMethod.register_calculator(self)
    ShippingRate.register_calculator(self)
  end
  
  def compute(order_or_line_items)
    return if order_or_line_items.nil?
    if order_or_line_items.is_a?(Order)
      total = order.item_total
    else
      total = order_or_line_items.map(&:amount).sum
    end
    
    total * self.preferred_flat_percent / 100.0
  end  
end

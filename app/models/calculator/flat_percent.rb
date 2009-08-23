class Calculator::FlatPercent < Calculator
  preference :percent, :decimal, :default => 0

  def self.description
    I18n.t("flat_percent")
  end

  def self.register
    super                                
    Coupon.register_calculator(self)
    ShippingMethod.register_calculator(self)
    ShippingRate.register_calculator(self)
  end

  # as object we always get line items, as calculable we have Coupon, ShippingMethod or ShippingRate
  def compute(object)
    if object.is_a?(Array)
      base = object.map{ |o| o.respond_to?(:amount) ? o.amount : o.to_d }.sum
    else
      base = object.respond_to?(:amount) ? object.amount : object.to_d
    end
    
    base * self.preferred_flat_percent
  end  
end

class Adjustment < ActiveRecord::Base
  acts_as_list :scope => :order
  
  belongs_to :order
  belongs_to :adjustment_source, :polymorphic => true

  validates_presence_of :amount
  validates_presence_of :description
  validates_numericality_of :amount, :allow_nil => true

  # Tries to calculate the adjustment, returns nil if adjustment could not be calculated.
  # raises RuntimeError if adjustment source didn't provide the caculator.
  def calculate_adjustment
    if adjustment_source
      calc = adjustment_source.calculator
      calc ||= adjustment_source.default_calculator if adjustment_source.respond_to?(:default_calculator)
      raise(RuntimeError, "#{self.class.name}##{id} doesn't have a calculator") unless calc
      calc.compute(adjustment_source)
    end
  end

  # Checks if adjustment is applicable for the order.
  # Should return _true_ if adjustment should be preserved and _false_ if removed.
  # Default behaviour is to preserve adjustment if amount is present and non 0.
  # Might (and should) be overriden in descendant classes, to provide adjustment specific behaviour.
  def applicable?
    amount && amount != 0
  end

  # Retrives amount of adjustment, if order hasn't been completed and amount is not set tries to calculate new amount.
  def amount
    amnt = read_attribute(:amount)
    if order && order.checkout_complete
      amnt
    else
      amnt == 0 ? (self.calculate_adjustment || 0) : amnt
    end
  end
  
  def update_amount
    new_amount = calculate_adjustment
    update_attribute(:amount, new_amount) if new_amount
  end

  def secondary_type; type; end

  private
  def ensure_negative_amount
    self.amount = -1 * self.amount.abs if self.amount
  end
end

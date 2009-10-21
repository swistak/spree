class Credit < Adjustment
  before_save :ensure_negative_amount
end

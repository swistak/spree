class ChargeRefactoring < ActiveRecord::Migration
  def self.up
    add_column :orders, :checkout_complete, :boolean
    Order.reset_column_information
    Order.all.each{|o| o.update_attribute(:checkout_complete, !!(o.checkout && o.checkout.completed_at))}

    change_column :adjustments, :amount, :integer, :null => true, :defaul => nil

    Adjustment.update_all "type = secondary_type"
    Adjustment.update_all "type = 'CouponCredit'", "type = 'Credit'"
    remove_column :adjustments, :secondary_type
  end

  def self.down
    remove_column :orders, :checkout_complete
    add_column :adjustments, :secondary_type, :string
    Adjustment.update_all "secondary_type = type"
    Adjustment.update_all "type = 'Charge'", "type like '%Charge'"
    Adjustment.update_all "type = 'Credit'", "type like '%Credit'"
    change_column :adjustments, :amount, :integer, :null => false, :defaul => 0
  end
end

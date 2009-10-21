require 'test_helper'

class TestAdjustment < Adjustment
  attr_accessor :applicable
  attr_accessor :adjustment_amount

  # true by default ;) I love tri-state logic
  def applicable?
    @applicable.nil? ? true : @applicable
  end

  def calculate_adjustment
    @adjustment_amount || 10
  end
end

class AdjustmentTest < ActiveSupport::TestCase
  should_validate_presence_of :description

  context "Adjustment with order" do
    setup do
      create_complete_order
      TestAdjustment.create(:order => @order, :description => "TestAdjustment")
      @adjustment = @order.reload.adjustments.select{|a| a.class==TestAdjustment}.first
    end

    should "find all types of charges" do
      Charge.create(:order => @order, :description => "TestCharge")
      ShippingCharge.create(:order => @order, :description => "TestCharge")
      TestCharge.create(:order => @order, :description => "TestCharge")
      assert_equal(5, @order.reload.charges.length) # 3 + 1 default tax charge
    end

    should "find all types of adjustments" do
      Charge.create(:order => @order, :description => "TestCharge")
      ShippingCharge.create(:order => @order, :description => "TestCharge")
      Adjustment.create(:order => @order, :description => "TestAdjustment")
      assert_equal(6, @order.reload.adjustments.length) # default shipping charge, default tax charge, test adjustment + 3
    end

    should "remove adjustments if they are no longet applicable" do
      @adjustment.applicable = false
      @order.update_totals
      assert_equal 2, @order.adjustments.length # tax charge nad shipping charge should still be there
      assert_nil Adjustment.find_by_id(@adjustment.id)
    end

    should "not remove adjustments if they are applicable" do
      @adjustment.applicable = true
      @order.update_totals
      assert_equal 3, @order.adjustments.length
      assert Adjustment.find_by_id(@adjustment.id)
    end

    context "with checkout finished" do
      setup do
        @order.complete!
      end

      should "save amounts of all adjustments" do
        assert @order.adjustments.reload.all{|a| a.read_attribute(:amount)}
      end

      should "not change amounts" do
        @adjustment.adjustment_amount = 20
        @order.update_totals
        assert_equal 10, @order.adjustments.select{|a| a.class==TestAdjustment}.first.amount
      end
    end
  end
end

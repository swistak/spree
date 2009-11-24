require 'test_helper'

class CheckoutTest < ActiveSupport::TestCase
  fixtures :gateways

  should_belong_to :bill_address

  context Checkout do
    setup { @checkout = Factory(:order).checkout }
    context "in payment state" do
      setup { @checkout.state = "payment" }
      context "next" do
        setup { @checkout.next! }
        should_change("@checkout.state", :to => "complete") { @checkout.state }
        should_change("@checkout.order.completed_at", :from => nil) { @checkout.order.completed_at }
      end
    end
  end
end

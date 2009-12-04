module CheckoutsHelper

  # TODO: do we need this method any more?
  def checkout_steps                                                      
    checkout_steps = %w{registration billing shipping shipping_method payment confirmation}
    checkout_steps.delete "registration" if current_user
    checkout_steps
  end
  
  def checkout_progress
    steps = Checkout.state_names.map do |state|
      text = t("checkout_steps.#{state}")
      if Checkout.state_names.index(@checkout.state) > Checkout.state_names.index(state)
        css_class = 'completed'
        text = link_to text, edit_order_checkout_url(@order, :step => state)
      elsif state == @checkout.state
        css_class = 'current'
      else
        css_class = nil
      end
      content_tag('li', content_tag('span', text), :class => css_class)
    end
    content_tag('ol', steps.join("\n"), :class => 'progress-steps', :id => "checkout-step-#{@checkout.state}")
  end
  
end

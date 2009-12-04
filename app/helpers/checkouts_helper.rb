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

      css_classes = []
      
      
      current_index = Checkout.state_names.index(@checkout.state)
      state_index = Checkout.state_names.index(state)

      if state_index < current_index
        css_classes <<'completed'
        text = link_to text, edit_order_checkout_url(@order, :step => state)
      end
      if state_index == current_index + 1
        css_classes << 'next'
      end
      if state == @checkout.state
        css_classes << 'current'
      end

      if state_index == 0
        css_classes << 'first'
      end
      if state_index == Checkout.state_names.length - 1
        css_classes << 'last'
      end

      # It'd be nice to have separate classes but combining them with a dash helps out for IE6 which only sees the last class
      content_tag('li', content_tag('span', text), :class => css_classes.join('-'))
    end
    content_tag('ol', steps.join("\n"), :class => 'progress-steps', :id => "checkout-step-#{@checkout.state}") + '<br clear="left" />'
  end
  
end

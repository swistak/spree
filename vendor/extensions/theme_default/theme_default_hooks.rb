class ThemeDefaultHooks < Spree::ThemeSupport::Hook::ViewListener

  # TODO: could we define these automatically by looking in app/views/hooks for partial views
  render_on :homepage_above_products, :partial => "shared/test_hook" 
  
  #def homepage_above_products(context)
  #   '<p>Above products</p>'
  #end
  #
  #def homepage_below_products(context)
  #   '<p>Below products</p>'
  #end

end

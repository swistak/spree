class ThemeDefaultHooks < Spree::Hook::ViewListener

  render_on :homepage_above_products, :partial => "shared/test_hook" 
  
  # def homepage_above_products(context)
  #   
  #   'hey there!'
  # end
end

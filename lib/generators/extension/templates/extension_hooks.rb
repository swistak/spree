class <%= class_name.gsub(/Extension$/, '') %>Hooks < Spree::ThemeSupport::Hook::ViewListener

  # render_on :homepage_above_products, :partial => "shared/my_partial" 

end

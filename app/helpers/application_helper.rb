# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # helper to determine if its appropriate to show the store menu
  def store_menu?
    return true unless %w{thank_you}.include? @current_action
    false
  end

  # Renders all the extension partials that may have been specified in the extensions
  def render_extra_partials(f)
    @extension_partials.inject("") do |extras, partial|
      extras += render :partial => partial, :locals => {:f => f}
    end
  end
  
  def flag_image(code)
    "#{code.to_s.split("-").last.downcase}.png"
  end
  
  # Helper module included in ApplicationHelper and ActionControllerso that
  # hooks can be called in views like this:
  # 
  #   <%= call_hook(:some_hook) %>
  #   <%= call_hook(:another_hook, :foo => 'bar' %>
  # 
  # Or in controllers like:
  #   call_hook(:some_hook)
  #   call_hook(:another_hook, :foo => 'bar')
  # 
  # Hooks added to views will be concatenated into a string.  Hooks added to
  # controllers will return an array of results.
  #
  # Several objects are automatically added to the call context:
  # 
  # * request => Request instance
  # * controller => current Controller instance
  # 
  def call_hook(hook, context={})
    if is_a?(ActionController::Base)
      default_context = {:controller => self, :request => request}
      Spree::Hook.call_hook(hook, default_context.merge(context))
    else
      default_context = {:controller => controller, :request => request}
      Spree::Hook.call_hook(hook, default_context.merge(context)).join(' ')
    end        
  end
end
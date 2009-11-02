# Yerked from the most awesome Redmine project http://redmine.org

module Spree
  module Hook
    include ActionController::UrlWriter

    @@listener_classes = []
    @@listeners = nil
    @@hook_listeners = {}
    
    class << self
      # Adds a listener class.
      # Automatically called when a class inherits from Spree::Hook::Listener.
      def add_listener(klass)
        raise "Hooks must include Singleton module." unless klass.included_modules.include?(Singleton)
        @@listener_classes << klass
        clear_listeners_instances
      end
      
      # Returns all the listerners instances.
      def listeners
        @@listeners ||= @@listener_classes.collect {|listener| listener.instance}
      end
 
      # Returns the listeners instances for the given hook.
      def hook_listeners(hook)
        @@hook_listeners[hook] ||= listeners.select {|listener| listener.respond_to?(hook)}
      end
      
      # Clears all the listeners.
      def clear_listeners
        @@listener_classes = []
        clear_listeners_instances
      end
      
      # Clears all the listeners instances.
      def clear_listeners_instances
        @@listeners = nil
        @@hook_listeners = {}
      end
      
      # Calls a hook.
      # Returns the listeners response.
      def call_hook(hook, context={})
        returning [] do |response|
          hls = hook_listeners(hook)
          if hls.any?
            hls.each {|listener| response << listener.send(hook, context)}
          end
        end
      end
    end

    # Base class for hook listeners.
    class Listener
      include Singleton
    end

    # Listener class used for views hooks.
    # Listeners that inherit this class will include various helpers by default.
    class ViewListener < Listener
      include ERB::Util
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::FormOptionsHelper
      include ActionView::Helpers::JavaScriptHelper
      include ActionView::Helpers::PrototypeHelper
      include ActionView::Helpers::NumberHelper
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::AssetTagHelper
      include ActionView::Helpers::TextHelper
      include ActionController::UrlWriter
      include ApplicationHelper

      # Default to creating links using only the path.  Subclasses can
      # change this default as needed
      def self.default_url_options
        {:only_path => true }
      end
      
      # Helper method to directly render a partial using the context:
      # 
      #   class MyHook < Spree::Hook::ViewListener
      #     render_on :view_issues_show_details_bottom, :partial => "show_more_data" 
      #   end
      #
      def self.render_on(hook, options={})
        define_method hook do |context|
          context[:controller].send(:render_to_string, {:locals => context}.merge(options))
        end
      end
    end
  end
end



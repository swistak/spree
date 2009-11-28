class Admin::ConfigurationsController < Admin::BaseController
  before_filter :initialize_extension_links, :only => :index
  
  class << self
    def add_link(text, path, description)
      unless @@extension_links.any?{|link| link[:link_text] == text}
        @@extension_links << {
          :link => path,
          :link_text => text,
          :description => description,
        }
      end
    end
  end

  protected

  def initialize_extension_links
    @extension_links = @@extension_links
  end

  @@extension_links = []
end

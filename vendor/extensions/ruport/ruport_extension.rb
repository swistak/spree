class RuportExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/ruport"

  # Please use ruport/config/routes.rb instead for extension routes.

  def self.require_gems(config)
    #require 'ruport'
    #require 'ruport/util'
    #require 'ruport/acts_as_reportable'
    config.gem "ruport", :version => '1.6.1'
    config.gem "ruport-util", :lib => 'ruport/util'
    config.gem "acts_as_reportable", :lib => 'ruport/acts_as_reportable'
  end

  def activate
    base = File.dirname(__FILE__)
    if (RAILS_ENV=="production")
      $: << File.join(File.dirname(__FILE__), 'app/reports/')
      Dir.glob(File.join(File.dirname(__FILE__), 'app/reports/**/*.rb')).each{|report|
        require(report)
      }
    else
      FileUtils.cp Dir.glob(File.join(base, "public/stylesheets/*.css")), File.join(RAILS_ROOT, "public/stylesheets/")
      FileUtils.cp Dir.glob(File.join(base, "public/javascripts/*.js")), File.join(RAILS_ROOT, "public/javascripts")
      $LOAD_PATH << File.join(base, 'app/reports')
      Dir.glob(File.join(File.dirname(__FILE__), 'app/reports/**/*.rb')).each{|report|
        load(report)
      }
    end

    Order.acts_as_reportable({
        :only => ['number']
    })
    LineItem.acts_as_reportable({
        :include => :variant,
        :only => ['quantity', 'price']
    })
    Variant.acts_as_reportable({
        :only => 'sku',
        :include => :product
    })
    Product.acts_as_reportable({
        :only => 'name'
    })
    Checkout.acts_as_reportable({
        :only => ['completed_at']
    })

    Variant.class_eval do
      def options_text
        self.option_values.map { |ov| ov.presentation }.to_sentence({:words_connector => ", ", :two_words_connector => ", "})
      end

      def display_name
        "#{product.name}" + (option_values.empty? ? '' : "(#{options_text})")
      end
    end

    LineItem.class_eval do
      def interest_percent
        Spree::Config[:interest] || 0
      end

      def interest
        interest_percent / BigDecimal("100") * total
      end
    end
  end
end

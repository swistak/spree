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
      require 'model_extensions_for_ruport'
    else
      FileUtils.cp Dir.glob(File.join(base, "public/stylesheets/*.css")), File.join(RAILS_ROOT, "public/stylesheets/")
      FileUtils.cp Dir.glob(File.join(base, "public/javascripts/*.js")), File.join(RAILS_ROOT, "public/javascripts")
      $LOAD_PATH << File.join(base, 'app/reports')
      Dir.glob(File.join(File.dirname(__FILE__), 'app/reports/**/*.rb')).each{|report|
        load(report)
      }
      load 'model_extensions_for_ruport.rb'
    end
  end
end

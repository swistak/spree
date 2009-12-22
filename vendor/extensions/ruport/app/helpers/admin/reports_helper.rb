module Admin
  module ReportsHelper
    def link_to_report(report, overrides={})
      label = overrides.delete(:label) || report.name
      action = overrides.delete(:action) || :edit

      options = report.attributes.symbolize_keys.merge(overrides.symbolize_keys)
      options = {
        :action => action,
        :id => report.id,
        :format => options[:format],
        report.class.to_s.tableize.singularize.to_sym => options
      }

      link_to label, options
    end

    def links_to_report(report, overrides={})
      ['html','pdf','csv'].map{|f|
        link_to_report(report, overrides.merge(:label => f, :format => f))
      }.join(" | ")
    end
  end
end

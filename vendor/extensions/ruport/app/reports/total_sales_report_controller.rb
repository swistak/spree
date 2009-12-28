class TotalSalesReportController < Ruport::Controller
  include ActionView::Helpers::NumberHelper
  required_option :report_title

  unless defined?(REGISTER_STAGES_ONCE)
    REGISTER_STAGES_ONCE = true
    stage :report_header, :document, :report_footer
  end

  def conditions(options)
    condts = ['orders.completed_at IS NOT NULL']
    unless options.start_at.blank?
      condts.first << " AND orders.completed_at > ?"
      condts << options.start_at
    end
    unless options.end_at.blank?
      condts.first << " AND orders.completed_at < ?"
      condts << options.end_at
    end
    condts
  end

  def prepare_table
    Order.report_table(:all,
        :only => ['total', 'item_total'],
        :methods => ['credit_total', 'charge_total', 'tax_total', 'ship_total'],
        :conditions => conditions(options)
    )
  end

  def t(name)
    I18n.t(name, :scope => :report, :default => I18n.t(name))
  end

  def setup
    table = prepare_table

    if table.size > 0
      totals = Table(%w[total item_total ship_total tax_total charge_total credit_total])

      totals << {
        "total"       => number_to_currency(table.sigma("total")),
        "item_total"  => number_to_currency(table.sigma("item_total")),
        "ship_total"  => number_to_currency(table.sigma("ship_total")),
        "tax_total"   => number_to_currency(table.sigma("tax_total")),
        "charge_total"=> number_to_currency(table.sigma("charge_total")),
        "credit_total"=> number_to_currency(table.sigma("credit_total"))
      }
      totals.rename_columns { |c| t(c) }
      self.data = {:totals => totals}
    else
      self.data = {}
    end
  end

  module Formatter
    class Csv < Ruport::Formatter::CSV
      renders :csv, :for => TotalSalesReportController

      def build_report_header
      end

      def build_document
        if data[:totals]
          output << data[:totals].to_csv(:show_table_headers => true)
        else
          output << I18n.t('no_data')
        end
      end

      def build_report_footer
      end
    end

    class HTML < Ruport::Formatter::HTML
      renders :html, :for => TotalSalesReportController

      def build_report_header
        default_header
      end

      def build_document
        if data[:totals]
          output << data[:totals].to_html(:show_table_headers => true)

        else
          output << "<div style='background-color: #eee'>#{I18n.t('no_data')}</div>"
        end
      end

      def build_report_footer
        output << "#{I18n.t(:generated_at)} #{Time.now.strftime('%d-%m-%Y %H:%M')}"
      end

    end

    class PDF < Ruport::Formatter::PDF
      renders :pdf, :for => TotalSalesReportController

      def build_report_header
        default_header
      end

      def build_document
        if data[:totals]
          draw_table(data[:totals],
                     :width => 525,
                     :font_size => 8,
                     :column_widths => {
                                         0 => 75,
                                         1 => 75,
                                         2 => 75,
                                         3 => 75,
                                         4 => 75,
                                         5 => 75
                     })
        else
          add_text I18n.t('no_data')
        end
      end

      def build_report_footer
      end

    end

  end

end

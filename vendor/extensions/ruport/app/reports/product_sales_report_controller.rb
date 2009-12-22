class ProductSalesReportController < Ruport::Controller
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

  def prepare_line_items_table
    LineItem.report_table(:all, {
        :only => ['quantity'],
        :methods => ['total'],
        :include => {
          :variant => {
            :only => 'sku',
            :methods => ['display_name']
          },
          :order => {
            :only => ['completed_at']
          }
        },
        :conditions => conditions(options)
      })
  end

  def t(name)
    I18n.t(name, :scope => :report, :default => I18n.t(name))
  end

  # def prepare_summary_table(table)
  #   summary_table_data = ['total', 'interest'].map{|c|
  #     [t(c), "%.2f PLN" % table.sigma(c)]
  #   }
  #   interest_brutto = (table.sigma('interest')*BigDecimal("1.22")).round(2)
  #   summary_table_data << [t('interest_brutto'), "%.2f PLN" % interest_brutto]
  #
  #
  #   Table(['summary', 'value'], :data => summary_table_data)
  # end

  def setup
    line_items_table = prepare_line_items_table
    if line_items_table.size > 0
      grouping = Grouping(line_items_table, :by => "variant.display_name")

      products = Table(%w[sku name total count])

      grouping.each do |name,group|
        products << { "sku"   => group.data.first.data["variant.sku"],
                      "name"  => name,
                      "total" => group.sigma("total"),
                      "count" => group.sigma("quantity") }
      end

      products.sort_rows_by!(options.sort_by.downcase, :order => :descending)
      products.replace_column('total') { |r| number_to_currency(r.total) }
      products.rename_columns { |c| t(c) }

      products = products.to_group
      self.data = {:products => products}
    else
      self.data = {}
    end
  end

  module Formatter
    class Csv < Ruport::Formatter::CSV
      renders :csv, :for => ProductSalesReportController

      def build_report_header
      end

      def build_document
        if data[:products]
          output << data[:products].to_csv(:show_table_headers => true)
        else
          output << I18n.t('no_data')
        end
      end

      def build_report_footer
      end
    end

    class HTML < Ruport::Formatter::HTML
      renders :html, :for => ProductSalesReportController

      def build_report_header
        default_header
      end

      def build_document
        if data[:products]
          output << data[:products].to_html(:show_table_headers => true)

        else
          output << "<div style='background-color: #eee'>#{I18n.t('no_data')}</div>"
        end
      end

      def build_report_footer
        output << "#{I18n.t(:generated_at)} #{Time.now.strftime('%d-%m-%Y %H:%M')}"
      end

    end

    class PDF < Ruport::Formatter::PDF
      renders :pdf, :for => ProductSalesReportController

      def build_report_header
        default_header
      end

      def build_document
        if data[:products]
          draw_table(data[:products],
                     :width => 525,
                     :font_size => 8,
                     :column_widths => {
                                         0 => 75,
                                         1 => 235,
                                         2 => 100,
                                         3 => 100
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

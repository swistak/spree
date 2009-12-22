class DetailedSalesReportController < Ruport::Controller
  required_option :report_title

  unless defined?(REGISTER_STAGES_ONCE)
    REGISTER_STAGES_ONCE = true
    stage :report_header, :document, :report_footer
  end

  CONDITIONS = lambda do |options|
    conditions = ['orders.completed_at IS NOT NULL']
    unless options.start_at.blank?
      conditions.first << " AND orders.completed_at > ?"
      conditions << options.start_at
    end
    unless options.end_at.blank?
      conditions.first << " AND orders.completed_at < ?"
      conditions << options.end_at
    end
    unless options.partner_id.blank?
      conditions.first << " AND orders.partner_id = ?"
      conditions << options.partner_id
    end
    conditions
  end

  def prepare_line_items_table
    LineItem.report_table(:all, {
        :only => ['quantity'],
        :methods => ['total', 'interest_percent', 'interest'],
        :include => {
          :variant => {
            :only => 'sku',
            :methods => ['display_name'],
            :include => {
              :product => {:only => {}}
            }
          },
          :order => {
            :only => ['number'],
          }
        },

        :filters => nil,
        :transforms => nil,
        :conditions => CONDITIONS.call(options),
        :order => "orders.completed_at ASC"
      })
  end

  def t(name)
    I18n.t(name, :scope => :report, :default => I18n.t(name))
  end

  def prepare_summary_table(table)
    summary_table_data = ['total', 'interest'].map{|c|
      [t(c), "%.2f PLN" % table.sigma(c)]
    }
    interest_brutto = (table.sigma('interest')*BigDecimal("1.22")).round(2)
    summary_table_data << [t('interest_brutto'), "%.2f PLN" % interest_brutto]


    Table(['summary', 'value'], :data => summary_table_data)
  end

  def setup
    line_items_table = prepare_line_items_table
    if line_items_table.size > 0
      summary_table    = prepare_summary_table(line_items_table)
      line_items_table.reorder('variant.sku', 'variant.display_name', 'quantity', 'total', 'order.number', 'interest_percent', 'interest')

      line_items_table.replace_column('interest_percent') { |r| r.interest_percent.to_s+" %" }
      line_items_table.replace_column('interest') { |r| "%.2f PLN" % r.interest }
      line_items_table.replace_column('total') { |r| "%.2f PLN" % r.total }

      line_items_table.rename_column("variant.sku", "variant SKU")
      line_items_table.rename_column("order.number", "order number")
      line_items_table.rename_column("total", "total_brutto")
      line_items_table.rename_columns { |c| t(c) }

      summary_table.rename_columns{|c| t(c)}


      grouping = Grouping(line_items_table, :by => I18n.t("order number"), :order => lambda{|o| Order.find_by_number(o.name).completed_at})
      self.data = {:orders => grouping, :summary => summary_table}
    else
      self.data = {}
    end
  end

  module Formatter
    class Csv < Ruport::Formatter::CSV
      renders :csv, :for => [DetailedSalesReportController]

      def build_report_header
        output.replace("")
      end

      def build_document
        if data[:orders]
          output << data[:orders].to_csv(:show_table_headers => true)
        else
          output << I18n.t('no_data')
        end
      end

      def build_report_footer
        #output.replace("")
      end
    end

    class Html < Ruport::Formatter::HTML
      renders :html, :for => [DetailedSalesReportController]

      def build_report_header
        default_header
      end

      def build_document
        if data[:orders]
          output << data[:orders].to_html(:show_table_headers => true)
          output << data[:summary].to_html(:show_table_headers => true)
        else
          output << "<div style='background-color: #eee;'>#{I18n.t('no_data')}</div>"
        end
      end

      def build_report_footer

      end
    end

    class PDF < Ruport::Formatter::PDF
      renders :pdf, :for => [DetailedSalesReportController]

      def build_report_header
        default_header
      end

      def build_document
        if orders = data[:orders]
          orders.each do |group_name, group|
            new_page_if_needed
            order = Order.find_by_number(group_name)
            add_text "Zamówienie numer <b>##{group_name}</b> zrealizowane <i>#{order.completed_at.strftime('%d-%m-%Y')}</i>"
            pdf.pad_bottom(15) do
              draw_table(group,
                         :width => 525,
                         :font_size => 8,
                         :column_widths => { # why hash? I have no idea.
                                             0 => 75,  # SKU
                                             1 => 235, # Opis
                                             2 => 30,  # Sztuk
                                             3 => 70,  # kwota sprzedaży
                                             4 => 55,  # prowzja
                                             5 => 60   # kwota prowizji
                         }
              )
            end
          end
        else
          add_text I18n.t('no_data')
        end
      end

      def build_report_footer
        if summary = data[:summary]
          new_section(100)

          pdf.pad(10) do
            draw_table summary,
                       :position => 230,
                       :width => 300,
                       :column_widths => {
                           0 => 200,
                           1 => 100,
                           }
          end
        end
      end

    end
  end
end

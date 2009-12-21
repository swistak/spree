class DetailedSalesReport < Ruport::Controller
  required_option :report_title

  unless defined?(REGISTER_STAGES_ONCE)
    REGISTER_STAGES_ONCE = true
    stage :report_header, :document, :report_footer
  end

  CONDITIONS = lambda do |options|
    conditions = ['orders.paid_at IS NOT NULL']
    unless options.start_at.blank?
      conditions.first << " AND orders.paid_at > ?"
      conditions << options.start_at
    end
    unless options.end_at.blank?
      conditions.first << " AND orders.paid_at < ?"
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
        :order => "orders.paid_at ASC"
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


      grouping = Grouping(line_items_table, :by => I18n.t("order number"), :order => lambda{|o| Order.find_by_number(o.name).paid_at})
      self.data = {:orders => grouping, :summary => summary_table}
    else
      self.data = {}
    end
  end
end

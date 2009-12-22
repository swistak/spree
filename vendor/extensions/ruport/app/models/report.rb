class Report < ActiveRecord::Base
  AVAILABLE_REPORTS = [
      'DetailedSalesReport', 'ProductSalesReport'
  ]
  REPORT_PATH = File.join(RAILS_ROOT, "public", "saved_reports")+"/"

  AVAILABLE_FORMATS = ['html', 'pdf', 'csv']

  validates_presence_of :format, :report_type, :report_title
  validates_inclusion_of :report_type, :in => AVAILABLE_REPORTS
  validates_inclusion_of :format,      :in => AVAILABLE_FORMATS

  has_many :report_options

  before_save :set_defaults


  def self.default
    AVAILABLE_REPORTS.first
  end

  def self.get_monthly_reports(options={})
    monthly_reports = []

    months_back = 0
    start_time = Time.now

    while Order.count(:conditions => ['orders.state IN (?) AND orders.updated_at < ?', ["paid", "shipped"], start_time]) > 0
      time = Time.now.at_beginning_of_month - months_back.months
      start_time = time.at_beginning_of_month
      end_time = time.at_end_of_month

      reports = AVAILABLE_REPORTS.map do |report_type|
        Report.new({
            :report_type => report_type,
            :report_title => I18n.t(report_type),
            :format => 'html',
            :start_at => start_time.to_date.to_s,
            :end_at => end_time.to_date.to_s,
            }.merge(options.symbolize_keys))
      end
      monthly_reports << [start_time.to_date, end_time.to_date, reports]
      months_back += 1
    end
    return(monthly_reports)
  end

  def set_defaults
    self.format = 'html' if self.format.blank?
    self.report_title = self.name if self.report_title.blank?
    #self.start_at = Time.now - 1.month
    #self.end_at = Time.now
  end

  def render(format = nil)
    set_defaults

    options = self.attributes.merge(self.preferences)

    format ||= self.format
    Timeout.timeout(180) do
      report_template.render(format.to_sym, options)
    end
  end

  def report_template
    "#{self.class}Controller".constantize
  end

  def file_name
    "#{Time.now.strftime("%Y-%m-%d")}_#{name.to_url}"
  end

  def name
    name = report_title.blank? ? I18n.t(report_type) : report_title
    name += "(#{comment})" unless comment.blank?
    return(name)
  end

  def orders
    Order.find(:all, :conditions => report_template.const_get("CONDITIONS").call(self)) unless report_type.blank?
  end

  def to_s
    name
  end
end

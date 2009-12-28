class Admin::ReportsController < Admin::BaseController
  before_filter :load_types
  skip_before_filter :verify_authenticity_token

  def load_types
    @report_types = Report::AVAILABLE_REPORTS
  end

  def index
    @reports = Report.find(:all)

    @monthly_reports = Report.get_monthly_reports

    @report = Report.default.constantize.new({
        :report_type => Report.default,
        :format => 'html',
        :report_title => I18n.t(Report.default),
      })
  end

  def new
    report_params = params[:report] || {
      :report_type => Report.default,
      :report_title => I18n.t(Report.default),
      :format => 'html',
    }
    @report = Report.new(report_params)
    render_report
  end
  
  def show
    @report = Report.find(params[:id])
    render_report
  end

  def edit
    @report_types.each do |report_type|
      type = report_type.to_s.tableize.singularize.to_sym
      if params.key? type

        if params["save"]
          if (report_id = params[type][:id] || params[:id])
            @report = Report.find(report_id)
            @report.update_attributes(params[type])
          else
            @report = params[type][:report_type].constantize.new(params[type])
            @report.save
            redirect_to(:action => :index) && return
          end
        else
          @report = params[type][:report_type].constantize.new(params[type])
        end

      end
    end

    if @report.nil?
        @report = Report.find(params[:id])
    end

    render_report
  end

  def destroy
    Report.find(params[:id]).destroy
    render_js_for_destroy
  end

  def options
    @report = params[:report_type].constantize.new({
        :report_type => params[:report_type],
        :format => 'html',
        :report_title => I18n.t(params[:report_type]),
      })
    render :partial => "form"
  end

  protected

  def render_report
    unless @report.valid?
      flash[:error] = t(:invalid_report)
      redirect_to :action => :index
      return
    end

    rendered_report = @report.render

    case @report.format.to_s.downcase
    when 'pdf'
      send_data(rendered_report,
        :type => "application/pdf",
        :filename => "#{@report.file_name}.pdf"
      )
    when 'csv'
      send_data(rendered_report,
        :type => "text/csv",
        :filename => "#{@report.file_name}.csv"
      )
    else
      @rendered_report = rendered_report
    end
  end
end

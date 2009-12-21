require 'detailed_sales_report'

module Formatter
  class Html < Ruport::Formatter::HTML
    renders :html, :for => [DetailedSalesReport]

    def build_report_header
      output.replace("")
      
      output << "<h2>#{options.report_title}</h2>"
      output << "#{I18n.t(:generated_at)} #{Time.now.strftime('%d-%m-%Y %H:%M')}"
      output << "<hr />"
    end

    def build_document
      if data[:orders]
        output << data[:orders].to_html(:show_table_headers => true)
        output << data[:summary].to_html(:show_table_headers => true)
      else
        output << '<div style="background-color: #eee;">Brak zamówień w określonym przedziale czasowym</div>'
      end
    end

    def build_report_footer
      
    end
  end
end

Ruport::Formatter::HTML.class_eval do
  # Renders individual rows for the table.
  def build_row(data = self.data)
    @odd = !@odd
    klass = @odd ? "odd" : "even"
    output <<
      "\t\t<tr class=\"#{klass}\">\n\t\t\t<td>" +
      data.to_a.join("</td>\n\t\t\t<td>") +
      "</td>\n\t\t</tr>\n"
  end

  # Generates <table> tags enclosing the yielded content.
  #
  # Example:
  #
  #   output << html_table { "<tr><td>1</td><td>2</td></tr>\n" }
  #   #=> "<table>\n<tr><td>1</td><td>2</td></tr>\n</table>\n"
  #
  def html_table
    @odd = false
    "<table>\n" << yield << "</table>\n"
  end
end
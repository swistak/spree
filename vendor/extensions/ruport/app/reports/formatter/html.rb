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

  def default_header
    output << "<h2>#{options.report_title}</h2>"
    output <<  options.start_at.strftime("<strong>From:</strong> %m/%d/%Y")
    output <<  options.end_at.strftime(" <strong>to:</strong> %m/%d/%Y")
    output << "<hr />"
  end
end
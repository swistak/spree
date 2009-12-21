require 'detailed_sales_report'

module Formatter
  class Csv < Ruport::Formatter::CSV
    renders :csv, :for => [DetailedSalesReport]

    def build_report_header
      output.replace("")
    end

    def build_document
      if data[:orders]
        output << data[:orders].to_csv(:show_table_headers => true)
      else
        output << "Brak zamówień w określonym przedziale czasowym"
      end
    end

    def build_report_footer
      #output.replace("")
    end
  end
end

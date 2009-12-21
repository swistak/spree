require 'detailed_sales_report'
gem 'prawn'
require 'prawn'
require 'prawn/table'
require 'prawn/format'

module Formatter
  class PrawnPdf < Ruport::Formatter::PDF
    renders :pdf, :for => [DetailedSalesReport]

    FONT = "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"

    def t(name)
      I18n.t(name, :scope => :report, :default => I18n.t(name))
    end

    def document
      @document ||= (options.document || Prawn::Document.new)
    end

    alias pdf document

    def table_body
      data.map { |e| e.to_a }
    end

    def build_report_header
      font FONT
      font_size 10

      document.font("#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf")
      image_path = File.join(RAILS_ROOT, 'public', 'images', 'logo.png')

      start_at = options.start_at.blank? ? '01-11-2009' : options.start_at.strftime('%d-%m-%Y')
      end_at   = (options.end_at || Time.now).strftime('%d-%m-%Y')

      pdf.bounding_box([200, pdf.bounds.absolute_top()-10], :width => 300) do
        add_text "<i>#{options.report_title}</i>", :align => :right
        add_text "za okres od: #{start_at}", :align => :right
        add_text "         do: #{end_at}", :align => :right
        pdf.move_down(5)
        pdf.text "#{t(:generated_at)}: #{Time.now.strftime('%d-%m-%Y %H:%M')}", :align => :right, :size => 8
      end

      top_left = pdf.bounds.absolute_top_left()
      pdf.image image_path,
                :at => [0, pdf.bounds.absolute_top()-10],
                :width => 164, # This 3 lines are here fo fix prawn png size bug,
                :height => 80, # values are experimental, report simply looks good with these
                :scale => 0.75 # If we upgrade to newer prawn this should be reewaluated

      pdf.move_down(5)
      pdf.pad(10){ hr }
    end

    def build_document
      if orders = data[:orders]
        orders.each do |group_name, group|
          new_page_if_needed
          order = Order.find_by_number(group_name)
          add_text "Zamówienie numer <b>##{group_name}</b> zrealizowane <i>#{order.paid_at.strftime('%d-%m-%Y')}</i>"
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
        add_text "<i>Brak zamówień w określonym przedziale czasowym</i>"
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

    def hr
      document.stroke_horizontal_rule
    end

    def draw_table(data, opts)
      headers = options.headers || data.column_names
      table_body = data.map { |e| e.to_a }
      pdf.table table_body, {
          :headers => headers,
          :row_colors => :pdf_writer,
          :position => :center,
          :font_size => 10,
          :vertical_padding => 2,
          :horizontal_padding => 5
      }.merge(opts)
    end

    def add_text(text, format_opts={})
      document.text(text, format_opts)
    end

    def finalize
      output << document.render
    end

    def new_section(spacer = 60)
      new_page_if_needed(spacer) { pdf.pad(5) { hr } }
    end

    def new_page_if_needed(spacer = 60, &block)
      if pdf.y < pdf.bounds.absolute_bottom() + spacer
        pdf.start_new_page
      elsif block
        block.call()
      end
    end

    def method_missing(name, *args, &block)
      if pdf.respond_to?(name)
        pdf.send(name, *args, &block)
      else
        super
      end
    end
  end
end
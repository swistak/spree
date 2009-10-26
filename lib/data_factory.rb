require 'test/test_helper'
require 'faker'
require 'factory_girl'
Dir.glob(SPREE_ROOT+"/test/factories/*.rb").each{|f| require(f)}

ActiveRecord::Base.class_eval do
  def self.delete_with_broken_associations
    reflect_on_all_associations(:belongs_to).each do |assoc|
      assoc_table_name = assoc.klass.table_name
      foreign_key = assoc.options[:foreign_key] || assoc.klass.name.foreign_key
      query = <<SQL
       #{table_name}.id IN (
         SELECT
           #{self.table_name}.id
         FROM
           #{self.table_name}
         LEFT OUTER JOIN
           #{assoc_table_name}
         ON
           #{self.table_name}.#{foreign_key} == #{assoc_table_name}.id
         WHERE
           #{assoc_table_name}.id IS NULL
       )
SQL
      
      delete_all(query.gsub(/\s+/, " "))
    end
  end
end

module DataFactory
  module_function

  attr_accessor :n

  # generates random number without lower limit (so it can be 0) that grows linerally
  def l(x); rand(x*@n);  end

  # generates random number with lower limit that grows linerally
  def lm(x, min=nil)
    min ||= x * @n / 2
    rand(x*@n) + min
  end

  # generates random number without lower limit (so it can be 0) that grows exponentially
  def e(x)
    rand(x**@n)
  end

  # generates random number with lower limit that grows  exponentially
  def em(x, min=nil)
    min ||= x * @n / 5
    rand(x**@n) + min*@n
  end

  def nm(min = @n)
    rand(@n) + min
  end

  # flips a coin ;)
  def flip(chance = 0.5)
    rand < chance
  end


  def clean_big_data
    [
      OptionType, OptionValue, Prototype, ShippingCategory,
      TaxCategory, Taxonomy, Taxon, Product
    ].each do |klass|
      klass.delete_all "name like 'bd_%'"
    end
    User.delete_all "login like 'bd_%'"

    [Order, Variant, LineItem, Address, Checkout, Shipment].each do |klass|
      klass.delete_with_broken_associations
    end
    puts "cleanup complete!"
  end

  def generate_variant_combinations(option_values)
    if option_values.length == 1
      option_values.first.map{|v| [v]}
    else
      result = []
      option_values.first.each do |value|
        result += generate_variant_combinations(option_values[1..-1]).map{|rv| rv.push(value) }
      end
      result
    end
  end

  def create_taxons(parent, level, max_level)
    nm(2).times do |x|
      pid = parent.name.split("-").last
      taxon = Taxon.new({
          :taxonomy_id => parent.taxonomy_id,
          :parent_id => parent.id,
          :name => "bd_taxon-#{pid}.#{x}",
        })
      taxon.save!
      if (level < max_level - 1) && flip
        create_taxons(taxon, level+1, max_level)
      else
        lm(2, 5).times do
          pr = @products.rand
          taxon.products << pr unless taxon.products.include?(pr)
        end
      end
    end
  end


  def generate_options
    @option_types = []
    nm.times do |x|
      ot = OptionType.create!({
          :name => "bd_ot#{x}",
          :presentation => "OptionType#{x}"
        })
      nm.times do |y|
        ot.option_values << OptionValue.create!({
            :option_type => ot,
            :name => "bd_ov#{x}-#{y}",
            :presentation => "OptionValue#{x}-#{y}"
          })
      end
      @option_types << ot
    end

    puts "OptionType: #{OptionType.count(:conditions => "name LIKE 'bd_%'")}"
    puts "OptionValue: #{OptionValue.count(:conditions => "name LIKE 'bd_%'")}"
  end

  def generate_prototypes
    @prototypes = []
    @prototypes << Prototype.create({:name => "bd_prototype0"})
    @option_types.each_with_index do |dot, x|
      proto = Prototype.new({
          :name => "bd_prototype#{x}"
        })
      proto.option_types << dot
      rand(@n).times do |x|
        ot = @option_types.rand
        proto.option_types << ot unless proto.option_types.include?(ot)
      end
      proto.save!
      @prototypes << proto
    end
    puts "Prototype: #{Prototype.count(:conditions => "name LIKE 'bd_%'")}"
  end

  def shipping_and_tax_categories
    @shipping_categories = []
    lm(3, 1).times do |x|
      @shipping_categories << Factory(:shipping_category, :name => "bd_shipping_category_#{x}")
    end
    @tax_categories = []
    lm(3, 1).times do |x|
      @tax_categories << Factory(:tax_category, :name => "bd_tax_category_#{x}")
    end
    puts "ShippingCategory: #{ShippingCategory.count(:conditions => "name LIKE 'bd_%'")}"
    puts "TaxCategory: #{TaxCategory.count(:conditions => "name LIKE 'bd_%'")}"
  end

  def products_and_variants
    @products = []
    @variants = []
    lm(50).times do |x|
      product = Product.create({
          :name => "bd_product#{x}",
          :description => Faker::Lorem.paragraphs(rand(5)+1).join("\n"),
          :tax_category => @tax_categories.rand,
          :shipping_category => @shipping_categories.rand,
          :prototype_id => @prototypes.rand.id,
          :price => x
        })
      pp product.errors unless product.valid?
      product.save!
      @products << product

      if product.option_types.empty?
        @variants << product.master
      else
        generate_variant_combinations(
          product.option_types.map{|ot| ot.option_values}
        ).select{ flip(0.3) }.each_with_index do |option_values, index|
          @variants << Variant.create!({
              :product => product,
              :option_values => option_values,
              :is_master => false,
              :sku => "#{product.sku}-#{index+1}"
            })
        end
      end

    end

    puts "Product: #{Product.count(:conditions => "name LIKE 'bd_%'")}"
    puts "Variant: #{Variant.count(:include => :product, :conditions => "products.name LIKE 'bd_%'")}"

  end

  def taxons_and_taxonomies
    @taxonomies = []
    @n.times do |x|
      taxonomy =  Taxonomy.create!({
          :name => "bd_-taxonomy-#{x}",
        })
      max_level = (@n/2) + 2
      create_taxons(taxonomy.root, 0, max_level)
      @taxonomies << taxonomy
    end

    puts "Taxonomy: #{Taxonomy.count(:conditions => "name LIKE 'bd_%'")}"
    puts "Taxon: #{Taxon.count(:conditions => "name LIKE 'bd_%'")}"
  end

  def users
    @users = []
    em(5, 2).times do |x|
      begin
        user = Factory.build(:user)
        user.login = "bd_#{x}"
        user.save!
        @users << user
      rescue ActiveRecord::RecordInvalid => e
        puts "#{e}: #{user.inspect}"
      end
    end

    puts "User: #{User.count(:conditions => "login LIKE 'bd_%'")}"
  end

  def orders_and_line_items
    t = Time.zone.now
    @orders = []
    @users.each do |user|
      l(5).times do |x|
        order = Factory(:order, :user => user)
        nm(1).times do |y|
          li = LineItem.new(:quantity => nm(1))
          li.order = order
          li.variant = @variants.rand
          p li.errors unless li.valid?
          li.save!
        end
        @orders << order
      end
    end
    puts "Orders: #{Order.count(:conditions => ["created_at > ?", t])}"
    puts "LineItem: #{LineItem.count(:conditions => ["created_at > ?", t])}"
  end

  def produce(n = nil)
    srand(666)
    @n = n || @n || 1
    t1 = Time.now

    desc = %w{small medium huge go-watch-tv see-you-tommorow}
    puts "Started data production process, producing: #{desc[@n-1] || "will-complete-after-you-are-dead"} amounts of data"
    clean_big_data
    generate_options
    generate_prototypes
    shipping_and_tax_categories
    products_and_variants
    taxons_and_taxonomies
    users
    orders_and_line_items
    t2 = Time.zone.now
    puts "Data generation took #{((t2-t1)/60).to_i} minutes"
    :ok
  end

  def tt(taxon, level = 0) 
    "  "*level + taxon.name + "(#{taxon.products.count})\n" +
      taxon.children.map{|c| tt(c, level+1)}.join("")
  end
end
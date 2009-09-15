class AddIsMasterToVariants < ActiveRecord::Migration
  def self.up
    change_table :variants do |t|
      t.boolean "is_master", :default => false
    end
    
    Variant.class_eval do
      # temporarily disable validation so we can pull off the migration
      def check_price
      end
    end
    
    ## Flag the first variant of each product as the "master" variant 
    variants = Variant.all
    unless variants.empty? 
      # select first variant of each product as "master" and flag it in the database
      master_variants = ActiveSupport::OrderedHash.new
      sorted_variants = variants.reject{|v| v.product_id.nil?}.sort{|a,b| a.product_id <=> b.product_id}.sort{|a,b| a.id <=> b.id}
      sorted_variants.each{|v| master_variants[v.product] ||= v }
      master_variants.each_pair{|product, v| v.update_attributes(:is_master => true, :price => product.attributes["master_price"])}
    end
  end

  def self.down
    change_table :variants do |t|
      t.remove "is_master"
    end
  end
end




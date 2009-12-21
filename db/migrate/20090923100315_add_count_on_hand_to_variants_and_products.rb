class AddCountOnHandToVariantsAndProducts < ActiveRecord::Migration
  def self.up
    add_column :variants, :count_on_hand, :integer, :default => 0, :null => false
    add_column :products, :count_on_hand, :integer, :default => 0, :null => false
    say_with_time 'Transfering inventory units with status on_hand to variants table...' do 
      execute %q{
        UPDATE 
          variants 
        SET 
          count_on_hand = (
            SELECT 
              COUNT(inventory_units.id) 
            FROM 
              inventory_units
            WHERE 
              inventory_units.variant_id = variants.id AND 
              state = E'on_hand'
          );
      }

      InventoryUnit.destroy_all(:state => "on_hand")
    end
    say_with_time 'Updating products count on hand' do
      execute %q{
        UPDATE
          products
        SET
          count_on_hand = (
            SELECT 
              SUM(variants.count_on_hand) 
            FROM 
              variants 
            WHERE 
              variants.product_id = products.id
          )
      }
    end
  end

  def self.down
    Variant.all.each do |v|
      v.count_on_hand.times do
        InventoryUnit.create(:variant => variant, :state => 'on_hand')
      end
    end  
    remove_column :variants, :count_on_hand
    remove_column :products, :count_on_hand
  end
end

class CreateReport < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.string :report_type    
      t.string :format  
      t.string :comment 
      t.string :report_title
      
      t.timestamp :start_at
      t.timestamp :end_at
    end
  end

  def self.down
    drop_table :reports
  end
end

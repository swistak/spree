class Taxonomy < ActiveRecord::Base
  has_many :taxons, :dependent => :destroy    
  has_one :root, :class_name => 'Taxon', :conditions => "parent_id is null"

  def after_create
    self.root = Taxon.create(:name => self.name, :taxonomy_id => self.id, :position => 1 )
  end

  def after_update
    self.root.update_attribute(:name, self.name)
  end
end

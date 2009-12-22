map.namespace :admin do |admin|
  admin.resources :reports, :member => {:destroy => :post, :edit => :any}, :collection => {:options => :get}
end

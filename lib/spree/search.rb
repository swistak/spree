module Spree::Search
  def retrive_products
    # taxon might be already set if this method is called from TaxonsController#show
    @taxon ||= params[:taxon] && Taxon.find_by_id(params[:taxon])
    @keywords = params[:keywords]

    if params[:product_group_name]
      @product_group = ProductGroup.find_by_permalink(params[:product_group_name])
    elsif params[:product_group_query]
      @product_group = ProductGroup.new.from_route(params[:product_group_query])
    else
      @product_group = ProductGroup.new
    end
    
    @product_group.add_scope('in_taxon', @taxon) unless @taxon.blank?
    @product_group.add_scope('keywords', @keywords) unless @keywords.blank?
    @product_group = @product_group.from_search(params[:search]) if params[:search]
    
    params[:search] = @product_group.scopes_to_hash

    @products_scope = @product_group.apply_on(Product.active)

    @products = @products_scope.paginate({
        :per_page => params[:per_page],
        :page     => params[:page],
      })
    @products_count = @products_scope.count

    return(@products)
  end
end

class CheckoutsController < Spree::BaseController
  include Spree::Checkout::Hooks
  include ActionView::Helpers::NumberHelper # Needed for JS usable rate information
  before_filter :load_data
  before_filter :set_state

  resource_controller :singleton
  actions :show, :edit, :update
  belongs_to :order

  ssl_required :update, :edit
    
  # GET /checkout is invalid but we'll assume a bookmark or user error and just redirect to edit (assuming checkout is still in progress)           
  show.wants.html { redirect_to edit_object_url }
  
  edit.before :edit_hooks  
  delivery.edit_hook :load_available_methods
  
  # alias original r_c method so we can handle any (gateway) exceptions that might be thrown
  # alias :rc_update :update
  # def update
  #   begin
  #     rc_update
  #   rescue Spree::GatewayError => ge
  #     logger.debug("#{ge}:\n#{ge.backtrace.join("\n")}")
  #     flash[:error] = t("unable_to_authorize_credit_card") + ": #{ge.message}"
  #     redirect_to edit_object_url and return
  #   rescue Exception => oe
  #     logger.debug("#{oe}:\n#{oe.backtrace.join("\n")}")
  #     flash[:error] = t("unable_to_authorize_credit_card") + ": #{oe.message}"
  #     logger.unknown "#{flash[:error]}  #{oe.backtrace.join("\n")}"
  #     redirect_to edit_object_url and return
  #   end
  # end    
    
  update.before :update_before
  update.after :update_after
  
  update do
    flash nil
    success.wants.html do
      if @checkout.completed_at 
        complete_order
        redirect_to order_url(@order, {:checkout_complete => true}) and next
      else
        render 'edit'
      end
    end
    
    # success.wants.html do
    #   if @order.reload.checkout_complete 
    #     if current_user
    #       current_user.update_attribute(:bill_address, @order.bill_address)
    #       current_user.update_attribute(:ship_address, @order.ship_address)
    #     end
    #     flash[:notice] = t('order_processed_successfully')
    #     order_params = {:checkout_complete => true}
    #     order_params[:order_token] = @order.token unless @order.user
    #     session[:order_id] = nil
    #     redirect_to order_url(@order, order_params) and next
    #   else
    #     # this means a failed filter which should have thrown an exception
    #     flash[:notice] = "Unexpected error condition -- please contact site support"
    #     redirect_to edit_object_url and next
    #   end
    # end

    # success.wants.js do
    #   @order.reload
    #   render :json => { :order_total => number_to_currency(@order.total),
    #                     :charge_total => number_to_currency(@order.charge_total),
    #                     :credit_total => number_to_currency(@order.credit_total),
    #                     :charges => charge_hash,
    #                     :credits => credit_hash,
    #                     :available_methods => rate_hash}.to_json,
    #          :layout => false
    # end

    # failure.wants.html do
    #   flash.now[:notice] = "Unexpected failure in card authorization -- please contact site support"
    #   render 'edit'
    #   #redirect_to edit_object_url and next
    # end
    # failure.wants.js do
    #   render :json => "Unexpected failure in card authorization -- please contact site support"
    # end
  end
    
  private
  def update_before
    # call the edit hooks for the current step in case we experience validation failure and need to edit again      
    edit_hooks
    @checkout.enable_validation_group(@checkout.state.to_sym)
  end
  
  def update_after
    update_hooks
    next_step
  end

  # Calls edit hooks registered for the current step  
  def edit_hooks  
    edit_hook @checkout.state.to_sym 
  end
  # Calls update hooks registered for the current step  
  def update_hooks
    update_hook @checkout.state.to_sym 
  end
    
  def object
    return @object if @object
    @object = parent_object.checkout
    unless params[:checkout] and params[:checkout][:coupon_code]
      # do not create these defaults if we're merely updating coupon code, otherwise we'll have a validation error
      if user = parent_object.user || current_user
        @object.shipment.address ||= user.ship_address
        @object.bill_address     ||= user.bill_address
      end
      @object.shipment.address ||= Address.default
      @object.bill_address     ||= Address.default
      @object.creditcard       ||= Creditcard.new(:month => Date.today.month, :year => Date.today.year)
    end
    @object
  end

  def load_data
    @countries = Country.find(:all).sort
    @shipping_countries = parent_object.shipping_countries.sort
    if current_user && current_user.bill_address
      default_country = current_user.bill_address.country
    else
      default_country = Country.find Spree::Config[:default_country_id]
    end
    @states = default_country.states.sort                                

    # prevent editing of a complete checkout  
    redirect_to order_url(parent_object) if parent_object.checkout_complete
  end

  def set_state
    object.state = params[:step] || Checkout.state_machine.initial_state(nil).name
    object.save(false)
  end
  
  def next_step      
    @checkout.next!
    # call edit hooks for this next step since we're going to just render it (instead of issuing a redirect)
    edit_hooks
  end
  
  def load_available_methods        
    @available_methods = rate_hash
    @checkout.shipment.shipping_method_id ||= @available_methods.first[:id]
  end

  def complete_order
    flash[:notice] = t('order_processed_successfully')
  end
  
  def rate_hash
    fake_shipment = Shipment.new :order => @order, :address => @order.ship_address
    @order.shipping_methods.collect do |ship_method|
      fake_shipment.shipping_method = ship_method
      { :id => ship_method.id,
        :name => ship_method.name,
        :rate => number_to_currency(ship_method.calculate_cost(fake_shipment)) }
    end
  end
end
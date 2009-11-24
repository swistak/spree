class Checkout < ActiveRecord::Base  
  extend ValidationGroup::ActiveRecord::ActsMethods
  #ActiveRecord::Errors.send :include, ValidationGroup::ActiveRecord::Errors
  #before_save :authorize_creditcard, :unless => "Spree::Config[:auto_capture]"
  #before_save :capture_creditcard, :if => "Spree::Config[:auto_capture]"
  after_save :process_coupon_code
  before_validation :clone_billing_address, :if => "@use_billing"
  
  belongs_to :order
  belongs_to :bill_address, :foreign_key => "bill_address_id", :class_name => "Address"
  has_one :shipment, :through => :order, :source => :shipments, :order => "shipments.created_at ASC"                       
  has_one :creditcard
  
  accepts_nested_attributes_for :bill_address
  accepts_nested_attributes_for :shipment
  accepts_nested_attributes_for :creditcard

  # for memory-only storage of creditcard details
  #attr_accessor :creditcard    
  attr_accessor :coupon_code
	#attr_accessor :confirmed
  attr_accessor :use_billing
  
  validates_presence_of :order_id

  validation_group :address, :fields=>[:bill_address_firstname, :bill_address_lastname, :bill_address_phone, 
                                       :bill_address_zipcode, :bill_address_state, :bill_address_lastname, 
                                       :bill_address_address1, :bill_address_city, :bill_address_statename, 
                                       :bill_address_zipcode, :shipment_address_firstname, :shipment_address_lastname, :shipment_address_phone, 
                                       :shipment_address_zipcode, :shipment_address_state, :shipment_address_lastname, 
                                       :shipment_address_address1, :shipment_address_city, :shipment_address_statename, 
                                       :shipment_address_zipcode]  
  validation_group :delivery, :fields => []

  def completed_at
    order.completed_at
  end
  
  alias :ar_valid? :valid?
  def valid?
    # will perform partial validation when @checkout.enabled_validation_group :step is called 
    result = ar_valid?
    return result unless validation_group_enabled?
    
    relevant_errors = errors.select { |attr, msg| @current_validation_fields.include?(attr.to_sym) }
    errors.clear
    relevant_errors.each { |attr, msg| errors.add(attr, msg) }
    relevant_errors.empty? 
  end
  
  # checkout state machine (see http://github.com/pluginaweek/state_machine/tree/master for details)
  state_machine :initial => 'address' do
    after_transition :to => 'complete', :do => :complete_order    
    event :next do
      transition :to => 'delivery', :from  => 'address'
      transition :to => 'payment', :from => 'delivery'
      transition :to => 'complete', :from => 'payment'
    end
  end
  

  private
  def clone_billing_address
    shipment.address = bill_address.clone #if shipment.address.firstname.nil?
    true
  end      
  
  def complete_order
    order.complete!
  end
  
  def authorize_creditcard
    return unless process_creditcard?
    cc = Creditcard.new(creditcard.merge(:address => self.bill_address, :checkout => self))
    return false unless cc.valid? 
    return false unless cc.authorize(order.total)
    return false unless order.complete
    true
  end

  def capture_creditcard
    return unless process_creditcard? 
    cc = Creditcard.new(creditcard.merge(:address => self.bill_address, :checkout => self))
    return false unless cc.valid?
    return false unless cc.purchase(order.total)
    return false unless order.complete
    order.pay
  end

  def process_creditcard?
    order and creditcard and confirmed and not creditcard[:number].blank?
  end

  def process_coupon_code
    return unless @coupon_code and coupon = Coupon.find_by_code(@coupon_code.upcase)
    coupon.create_discount(order)       
    # recalculate order totals
    order.save
  end

end

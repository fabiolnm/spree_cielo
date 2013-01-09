Spree::Order.class_eval do
  def available_payment_options
    @available_payment_options ||= available_payment_methods.collect { |m|
      payments.build payment_method_id: m.id
    }
  end
end

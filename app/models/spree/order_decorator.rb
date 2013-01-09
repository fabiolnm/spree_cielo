Spree::Order.class_eval do
  accepts_nested_attributes_for :payments, reject_if: proc { |attrs|
    attrs[:payment_method_id].blank?
  }

  def available_payment_options
    @available_payment_options ||= available_payment_methods.collect { |m|
      payments.build payment_method_id: m.id, source_attributes: { }
    }
  end
end

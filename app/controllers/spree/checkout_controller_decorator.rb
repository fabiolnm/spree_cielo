Spree::CheckoutController.class_eval do
  prepend_before_filter :request_authorization_at_cielo_hosted_page

  private
  def object_params
    # For payment step, filter order parameters to produce the expected nested attributes for a single payment and its source, discarding attributes for payment methods other than the one selected
    if @order.payment?
      if params[:payment_source].present? && source_params = params.delete(:payment_source)[params[:order][:payments_attributes].first[:payment_method_id].underscore]
        params[:order][:payments_attributes].first[:source_attributes] = source_params
      end
      # this code is brittle and was moved to a before_save callback
      #if (params[:order][:payments_attributes])
      #  params[:order][:payments_attributes].first[:amount] = @order.total
      #end
    end
    params[:order]
  end

  def request_authorization_at_cielo_hosted_page
    return unless request.put? and params[:state] == "payment"

    payment = Spree::Order.new(params[:order]).payment
    if payment.valid?
      method = payment.payment_method
      if method.type == "SpreeCielo::HostedBuyPagePayment::Gateway"
        load_order
        txn = method.authorization_transaction @order, payment.source, request.url
        redirect_to txn.url_autenticacao
      end
    end
  end
end

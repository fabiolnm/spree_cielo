Spree::CheckoutController.class_eval do
  prepend_before_filter :request_authorization_at_cielo_hosted_page

  def cielo_callback
    update
  end

  private
  def request_authorization_at_cielo_hosted_page
    return unless request.put? and params[:state] == "payment"

    load_order
    payment = Spree::Order.new(object_params).payment
    if payment.valid?
      method = payment.payment_method
      if method.type == "SpreeCielo::HostedBuyPagePayment::Gateway"
        source = payment.source

        callback_url = request.url.gsub request.path, cielo_callback_path
        txn = method.authorization_transaction @order, source, callback_url

        # FIXME handle transaction when response is error
        payment = @order.payments.create source_attributes: {
          xml: txn.xml,
          tid: txn.tid,
          flag: source.flag,
          status: txn.status,
          url: txn.url_autenticacao,
          installments: source.installments
        }, payment_method_id: method.id

        redirect_to txn.url_autenticacao
      end
    end
  end
end

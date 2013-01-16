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

        if txn.success?
          payment = @order.payments.create source_attributes: {
            xml: txn.xml,
            tid: txn.tid,
            flag: source.flag,
            status: txn.status,
            url: txn.url_autenticacao,
            installments: source.installments
          }, payment_method_id: method.id

          redirect_to txn.url_autenticacao
        else
          @order.payments.create source_attributes: {
            xml: txn.xml,
            status: txn.codigo,
            flag: source.flag,
            installments: source.installments
          }, payment_method_id: method.id

          flash[:error] = t :payment_processing_failed
          redirect_to checkout_state_path @order.state
        end
      end
    end
  end
end

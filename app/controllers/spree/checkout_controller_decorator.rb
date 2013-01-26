Spree::CheckoutController.class_eval do
  prepend_before_filter :request_authorization_at_cielo_hosted_page

  def cielo_callback
    payment = @order.payment
    if is_cielo? payment
      if @order.next
        state_callback :after
        if @order.state == 'complete' || @order.completed?
          flash.notice = t :order_processed_successfully
          flash[:commerce_tracking] = 'nothing special'
          redirect_to completion_route
          return
        end
      else
        flash[:error] = t :payment_processing_failed
      end
    end
    redirect_to checkout_state_path @order.state
  end

  private
  def is_cielo? payment
    unless payment.nil?
      method = payment.payment_method
      return method if method.type == "SpreeCielo::HostedBuyPagePayment::Gateway"
    end
  end

  def request_authorization_at_cielo_hosted_page
    return unless request.put? and params[:state] == "payment"

    load_order
    payment = Spree::Order.new(object_params).payment
    method = is_cielo? payment
    if method and payment.valid?
        source = payment.source

        callback_url = request.url.gsub request.path, cielo_callback_path
        txn = method.authorization_transaction @order, source, callback_url

        url = checkout_state_path @order.state
        if txn.success?
          payment = @order.payments.build source_attributes: {
            xml: txn.xml,
            flag: source.flag,
            status: txn.status,
            url: txn.url_autenticacao,
            installments: source.installments
          }, payment_method_id: method.id
          payment.response_code = txn.tid
          payment.save

          url = txn.url_autenticacao
        else
          @order.payments.create source_attributes: {
            xml: txn.xml,
            status: txn.codigo,
            flag: source.flag,
            installments: source.installments
          }, payment_method_id: method.id
          flash[:error] = t :payment_processing_failed
        end
        fire_event('spree.checkout.update')
        redirect_to url
    end
  end
end

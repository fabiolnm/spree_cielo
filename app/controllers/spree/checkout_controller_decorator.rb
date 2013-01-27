Spree::CheckoutController.class_eval do
  prepend_before_filter :request_authorization_at_cielo_hosted_page

  def cielo_callback
    if current_cielo_payment
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
  def is_cielo? payment_method
    payment_method.is_a? SpreeCielo::HostedBuyPagePayment::Gateway and payment_method
  end

  def before_payment
    # disables spree default behavior that erases previous payment history
    # current_order.payments.destroy_all if request.put?
  end

  def request_authorization_at_cielo_hosted_page
    return unless request.put? and
      params[:state] == "payment" and
      method = is_cielo?(payment_method_from_params)

    url = checkout_state_path @order.state
    if payment.valid?
      callback_url = request.url.gsub request.path, cielo_callback_path
      txn = method.authorization_transaction @order, payment.source, callback_url

      if txn.success?
        url = txn.url_autenticacao
        payment.response_code = txn.tid
      else
        flash[:error] = t :payment_processing_failed
      end

      payment.save
      res = ActiveMerchant::Billing::Response.new txn.success?, txn.xml
      payment.send :record_log, res

      fire_event 'spree.checkout.update'
    end
    redirect_to url
  end

  def payment_method_from_params
    load_order
    if @payment_params = object_params[:payments_attributes].first
      if method_id = @payment_params[:payment_method_id]
        Spree::PaymentMethod.find method_id
      end
    end
  end

  def payment
    return @payment unless @payment.nil?

    @payment = current_cielo_payment
    if @payment
      @payment.update_attributes @payment_params
      @payment
    else
      @payment = @order.payments.build @payment_params
    end
  end

  def current_cielo_payment
    @order.payments.detect { |p|
      p.checkout? and is_cielo? p.payment_method
    }
  end
end

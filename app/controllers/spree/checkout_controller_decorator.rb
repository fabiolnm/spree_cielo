Spree::CheckoutController.class_eval do
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
end

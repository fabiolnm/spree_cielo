Spree::Payment.class_eval do
  after_save :set_order_amount

  def set_order_amount
    update_column :amount, order.amount
  end
end

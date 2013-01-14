class AddResponseColumnsToCieloPayment < ActiveRecord::Migration
  def change
    add_column :spree_cielo_hosted_buy_page_payments, :xml, :text
    add_column :spree_cielo_hosted_buy_page_payments, :tid, :string
    add_column :spree_cielo_hosted_buy_page_payments, :url, :string
    add_column :spree_cielo_hosted_buy_page_payments, :status, :integer
  end
end

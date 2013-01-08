class CreateSpreeCieloHostedBuyPagePayments < ActiveRecord::Migration
  def change
    create_table :spree_cielo_hosted_buy_page_payments do |t|
      t.string :flag
      t.integer :installments

      t.timestamps
    end
  end
end

module SpreeCielo
  class HostedBuyPagePayment < ActiveRecord::Base
    attr_accessible :flag, :installments

    class Gateway < Spree::Gateway
      def payment_source_class
        HostedBuyPagePayment
      end

      def provider_class
        self.class
      end

      def authorize(money, source, options)
        order = source.payments.first.order
      end
    end
  end
end

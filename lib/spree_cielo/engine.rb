module SpreeCielo
  class Engine < ::Rails::Engine
    isolate_namespace SpreeCielo

    initializer "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods += [
        SpreeCielo::HostedBuyPagePayment::Gateway
      ]
    end
  end
end

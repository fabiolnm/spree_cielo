module SpreeCielo
  class Engine < ::Rails::Engine
    isolate_namespace SpreeCielo

    initializer "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods += [
        SpreeCielo::HostedBuyPagePayment::Gateway
      ]
    end

    config.to_prepare do
      # Load engine's model / class decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
  end
end

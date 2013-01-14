SpreeCielo::Engine.routes.draw do
end

Spree::Core::Engine.routes.append do
  get '/checkout/callback/cielo',
    to: 'checkout#cielo_callback',
    as: :cielo_callback
end

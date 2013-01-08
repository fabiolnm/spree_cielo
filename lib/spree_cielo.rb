require "spree_cielo/engine"

module SpreeCielo
  SUPPORTED_FLAGS = [
    :visa, :mastercard, :amex, :elo, :diners, :discover
  ]
  MAX_INSTALLMENTS = 3
end

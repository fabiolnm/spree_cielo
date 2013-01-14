module SpreeCielo
  class HostedBuyPagePayment < ActiveRecord::Base
    attr_accessible :flag, :installments, :xml, :tid, :status, :url

    has_one :payment, class_name: 'Spree::Payment', foreign_key: :source_id

    class Gateway < Spree::Gateway
      attr_accessible :preferred_api_number,
        :preferred_api_key, :preferred_soft_descriptor

      preference :api_number, :string
      preference :api_key, :string
      preference :soft_descriptor, :string

      after_initialize do
        self.preferred_api_number      = api_number
        self.preferred_api_key         = api_key
        self.preferred_soft_descriptor = soft_descriptor
      end

      def payment_source_class
        HostedBuyPagePayment
      end

      def provider_class
        self.class
      end

      # determine what partial will be rendered for this method type
      def method_type
        "cielo_hosted"
      end

      def api_number
        if preferences[:test_mode]
          Cieloz::DadosEc::TEST_MOD_CIELO.numero
        else
          preferences[:api_number]
        end
      end

      def api_key
        if preferences[:test_mode]
          Cieloz::DadosEc::TEST_MOD_CIELO.chave
        else
          preferences[:api_key]
        end
      end

      def soft_descriptor
        preferences[:soft_descriptor] || ""
      end

      def authorize money, payment, options = {}
        # validate payment via requisicao-consulta service
        ActiveMerchant::Billing::Response.new true, ''
      end

      def authorization_transaction order, source, callback_url
        ec = Cieloz::DadosEc.new numero: api_number, chave: api_key
        pedido = Cieloz::RequisicaoTransacao::DadosPedido
        .new numero: order.number,
          valor: (order.total * 100).round,
          moeda: 986, # TODO use https://github.com/hexorx/countries
          idioma: "PT",
          descricao: "", # TODO provide a description?
          data_hora: Time.now,
          soft_descriptor: soft_descriptor

        pagamento = Cieloz::RequisicaoTransacao::FormaPagamento.new bandeira: source.flag
        pagamento.parcelado_loja source.installments

        txn = Cieloz::RequisicaoTransacao.new
        txn.dados_ec = ec
        txn.dados_pedido = pedido
        txn.forma_pagamento = pagamento
        txn.url_retorno = callback_url
        txn.autorizacao_direta
        txn.nao_capturar_automaticamente

        txn.submit
      end
    end
  end
end

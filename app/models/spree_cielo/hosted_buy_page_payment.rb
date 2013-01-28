module SpreeCielo
  class HostedBuyPagePayment < ActiveRecord::Base
    attr_accessible :flag, :installments

    has_one :payment, class_name: 'Spree::Payment', foreign_key: :source_id

    # See http://guides.spreecommerce.com/payment_gateways.html, chapter 3
    # for a complete payment status list
    def actions
      res = []
      res << :capture if payment.pending?
      res << :void  if payment.completed?
      res
    end

    def status
      last_log = payment.log_entries.last
      if last_log
        xml = YAML::load(last_log.details).message
        status = Cieloz::Transacao.from(xml).status
        Cieloz::Transacao::STATUSES[status.to_s]
      end
    end

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

      def authorize money, source, options = {}
        tid = source.payment.response_code

        # validate payment via requisicao-consulta service
        operation = Cieloz::RequisicaoConsulta.new dados_ec: ec, tid: tid
        process_and_log operation, :autorizada?
      end

      def capture money, tid, options = {}
        operation = Cieloz::RequisicaoCaptura.new dados_ec: ec, tid: tid
        process_and_log operation, :capturada?
      end

      def void tid, options = {}
        operation = Cieloz::RequisicaoCancelamento.new dados_ec: ec, tid: tid
        process_and_log operation, :cancelada?
      end

      def authorization_transaction order, source, callback_url
        pedido = Cieloz::RequisicaoTransacao::DadosPedido
        .new numero: order.number,
          valor: (order.total * 100).round,
          moeda: 986, # TODO use https://github.com/hexorx/countries
          idioma: "PT",
          descricao: "", # TODO provide a description?
          data_hora: Time.now,
          soft_descriptor: soft_descriptor

        pagamento = Cieloz::RequisicaoTransacao::FormaPagamento.new
                    .parcelado_loja source.flag, source.installments

        txn = Cieloz::RequisicaoTransacao.new
        txn.dados_ec = ec
        txn.dados_pedido = pedido
        txn.forma_pagamento = pagamento
        txn.url_retorno = callback_url
        txn.autorizacao_direta
        txn.nao_capturar_automaticamente

        response, log = process txn, :criada?
        source.payment.send :record_log, log
        response
      end

      private
      def ec
        Cieloz::DadosEc.new numero: api_number, chave: api_key
      end

      def process operation, success_criteria
        log, success = '', false
        response = operation.submit
        if response
          log = response.xml
          success = response.send success_criteria
        else
          log = operation.errors.messages
        end
        [ response, ActiveMerchant::Billing::Response.new(success, log) ]
      end

      def process_and_log operation, success_criteria
        process(operation, success_criteria).last
      end
    end
  end
end

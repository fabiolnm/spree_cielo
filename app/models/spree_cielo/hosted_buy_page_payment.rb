module SpreeCielo
  class HostedBuyPagePayment < ActiveRecord::Base
    attr_accessible :flag, :installments, :xml, :tid, :status, :url

    has_one :payment, class_name: 'Spree::Payment', foreign_key: :source_id

    def actions
      %w(capture cancel)
    end

    def display_status
      Cieloz::Transacao::STATUSES[status.to_s]
    end

    def formatted_xml
      format_xml xml
    end

    def format_xml source
      indented = Nokogiri::XML(source).to_xml

      escaped = CGI::escapeHTML indented
      escaped.gsub! " ", "&nbsp;"
      escaped.gsub! "\n", "<br />"

      escaped.html_safe
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

      def authorize money, payment, options = {}
        response = ''
        autorizada = false

        # validate payment via requisicao-consulta service
        consulta = Cieloz::RequisicaoConsulta.new dados_ec: ec, tid: payment.tid
        res = consulta.submit
        if consulta.valid?
          autorizada = res.autorizada?
          response = res.xml if not autorizada
        else
          response = consulta.errors.messages
        end
        ActiveMerchant::Billing::Response.new autorizada, response
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

        txn.submit
      end

      private
      def ec
        Cieloz::DadosEc.new numero: api_number, chave: api_key
      end
    end
  end
end

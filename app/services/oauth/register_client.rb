# frozen_string_literal: true

module Oauth
  # RFC 7591 registration for public clients. Doorkeeper 5.9 does not ship this.
  class RegisterClient
    GRANTABLE = (ApiToken::SCOPES + %w[offline_access]).freeze
    REFRESH_TTL = 90.days
    NAME_LIMIT = 80
    URI_LIMIT = 5

    # Registration was refused. code is the OAuth error name.
    class Rejected < StandardError
      attr_reader :code

      def initialize(code)
        @code = code
        super
      end
    end

    def self.call(raw)
      new(raw).call
    end

    def initialize(raw)
      @raw = raw.to_h.symbolize_keys
    end

    def call
      raise Rejected, 'invalid_client_metadata' unless acceptable?

      document(create_application)
    rescue ActiveRecord::RecordInvalid
      raise Rejected, 'invalid_client_metadata'
    end

    private

    attr_reader :raw

    def acceptable?
      name_ok? && uris_ok? && auth_method_ok? && grants_ok? && response_types_ok?
    end

    def name_ok?
      name.present? && name.length <= NAME_LIMIT
    end

    def uris_ok?
      uris.present? && uris.size <= URI_LIMIT && uris.all? { |uri| Redirects.allowed?(uri) }
    end

    def auth_method_ok?
      raw[:token_endpoint_auth_method].blank? || raw[:token_endpoint_auth_method] == 'none'
    end

    def grants_ok?
      list = Array(raw[:grant_types])
      list.blank? || (list - %w[authorization_code refresh_token]).empty?
    end

    def response_types_ok?
      list = Array(raw[:response_types])
      list.blank? || list == ['code']
    end

    def name
      raw[:client_name].to_s.squish
    end

    def uris
      Array(raw[:redirect_uris]).map { |uri| uri.to_s.squish }.compact_blank
    end

    def create_application
      Doorkeeper::Application.create!(
        name:, redirect_uri: uris.join("\n"), confidential: false, scopes: GRANTABLE.join(' ')
      )
    end

    def document(application)
      {
        client_id: application.uid,
        client_name: application.name,
        redirect_uris: uris,
        grant_types: %w[authorization_code refresh_token],
        response_types: ['code'],
        token_endpoint_auth_method: 'none'
      }
    end
  end
end

# frozen_string_literal: true

module Oauth
  # Redirect URIs a dynamically registered client may use.
  class Redirects
    HOSTS = %w[agent.meta.ai chat.openai.com chatgpt.com claude.ai claude.com].freeze
    LOOPBACK = %w[localhost 127.0.0.1].freeze

    def self.allowed?(value)
      uri = URI.parse(value.to_s)
      return false unless http?(uri)

      public_host?(uri) || (Rails.env.local? && loopback?(uri))
    rescue URI::InvalidURIError
      false
    end

    def self.http?(uri)
      uri.is_a?(URI::HTTP) && uri.host.present? && uri.fragment.nil? && uri.userinfo.nil?
    end

    def self.public_host?(uri)
      uri.scheme == 'https' && HOSTS.include?(uri.host)
    end

    def self.loopback?(uri)
      uri.scheme == 'http' && LOOPBACK.include?(uri.host)
    end

    private_class_method :http?, :public_host?, :loopback?
  end
end

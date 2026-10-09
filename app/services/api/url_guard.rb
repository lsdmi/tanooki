# frozen_string_literal: true

require 'ipaddr'
require 'resolv'

module Api
  # Decides whether a chapter-image URL is safe to fetch. Private, loopback, and link-local
  # addresses are refused, including when a public name resolves to one of them.
  module UrlGuard
    BLOCKED = [
      '0.0.0.0/8', '10.0.0.0/8', '100.64.0.0/10', '127.0.0.0/8', '169.254.0.0/16',
      '172.16.0.0/12', '192.0.0.0/24', '192.0.2.0/24', '192.168.0.0/16',
      '198.18.0.0/15', '198.51.100.0/24', '203.0.113.0/24', '224.0.0.0/4', '240.0.0.0/4',
      '::/128', '::1/128', 'fc00::/7', 'fe80::/10', 'ff00::/8'
    ].map { |cidr| IPAddr.new(cidr) }.freeze

    def self.uri!(url)
      uri = URI.parse(url.to_s)
      raise Error.new('unsafe_url', :unprocessable_entity) unless http?(uri)

      uri
    rescue URI::InvalidURIError
      raise Error.new('unsafe_url', :unprocessable_entity)
    end

    def self.public_address!(host)
      addresses = resolve(host)
      unsafe = addresses.empty? || addresses.any? { |ip| blocked?(ip) }
      raise Error.new('unsafe_url', :unprocessable_entity) if unsafe

      addresses.first
    end

    def self.http?(uri)
      uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.blank? && !forbidden_name?(uri.host)
    end

    def self.forbidden_name?(host)
      name = host.to_s.downcase.delete_suffix('.')
      name == 'localhost' || name.end_with?('.localhost', '.local', '.internal')
    end

    def self.resolve(host)
      return [IPAddr.new(host)] if literal?(host)

      Resolv.getaddresses(host).map { |ip| IPAddr.new(ip) }
    rescue Resolv::ResolvError, IPAddr::InvalidAddressError
      []
    end

    def self.literal?(host)
      IPAddr.new(host)
      true
    rescue IPAddr::InvalidAddressError
      false
    end

    def self.blocked?(addr)
      addr = addr.native if addr.ipv4_mapped?
      BLOCKED.any? { |range| range.family == addr.family && range.include?(addr) }
    end
  end
end

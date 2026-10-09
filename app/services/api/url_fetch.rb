# frozen_string_literal: true

require 'net/http'
require 'tempfile'

module Api
  # Downloads a chapter image. The connection is pinned to an address UrlGuard already accepted,
  # redirects are checked again, and the body stops at 20 MB.
  class UrlFetch
    MAX_BYTES = 20.megabytes
    TIMEOUT = 10
    MAX_REDIRECTS = 3
    REDIRECTS = %w[301 302 303 307 308].freeze

    Response = Struct.new(:code, :location, :body) do
      def redirect? = UrlFetch::REDIRECTS.include?(code)
      def success? = code == '200'
    end

    def self.to_tempfile(url)
      file = Tempfile.new(['chapter-image', '.bin'])
      file.binmode
      file.write(bytes(url))
      file.rewind
      file
    rescue StandardError
      file&.close!
      raise
    end

    def self.bytes(url, hops = 0)
      raise Error.new('unsafe_url', :unprocessable_entity) if hops > MAX_REDIRECTS

      uri = UrlGuard.uri!(url)
      response = fetch(uri, UrlGuard.public_address!(uri.host))
      return bytes(next_url(uri, response.location), hops + 1) if response.redirect?
      raise Error.new('image_fetch_failed', :unprocessable_entity) unless response.success?

      response.body
    end

    def self.fetch(uri, address)
      Timeout.timeout(TIMEOUT) { http_get(uri, address) }
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError
      raise Error.new('image_timeout', :unprocessable_entity)
    end

    def self.http_get(uri, address)
      built = nil
      client(uri, address).start do |http|
        http.request(request_for(uri)) { |raw| built = build_response(raw) }
      end
      built
    end

    def self.client(uri, address)
      http = Net::HTTP.new(uri.host, uri.port)
      http.ipaddr = address.to_s
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT
      http.use_ssl = uri.is_a?(URI::HTTPS)
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER if http.use_ssl?
      http
    end

    def self.request_for(uri)
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Baka/1.0'
      request
    end

    def self.build_response(raw)
      if REDIRECTS.include?(raw.code)
        discard_body(raw)
        return Response.new(raw.code, raw['location'], nil)
      end

      Response.new(raw.code, nil, read_body(raw))
    end

    def self.read_body(raw, limit: MAX_BYTES)
      body = +''.b
      raw.read_body do |chunk|
        body << chunk
        raise Error.new('image_too_large', :content_too_large) if body.bytesize > limit
      end
      body
    end

    def self.discard_body(raw)
      read = 0
      raw.read_body do |chunk|
        read += chunk.bytesize
        raise Error.new('image_too_large', :content_too_large) if read > MAX_BYTES
      end
    end

    def self.next_url(uri, location)
      URI.join(uri, location.to_s).to_s
    rescue URI::InvalidURIError
      raise Error.new('unsafe_url', :unprocessable_entity)
    end

    private_class_method :fetch, :client, :request_for, :build_response, :discard_body, :next_url
  end
end

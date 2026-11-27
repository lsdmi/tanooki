# frozen_string_literal: true

require 'net/http'

module Fictions
  # Asks Hikka's public API whether a novel slug exists. Only an explicit 404 is :not_found. Any other answer, including
  # a timeout or a 403 from Hikka's rate limit, is :unavailable, so Hikka being down never blocks saving a fiction.
  class HikkaLookup
    BASE_URL = 'https://api.hikka.io'
    TIMEOUT = 3
    CONNECTION = { use_ssl: true, open_timeout: TIMEOUT, read_timeout: TIMEOUT }.freeze

    def initialize(slug)
      @slug = slug
    end

    def call
      case status_code
      when '200' then :found
      when '404' then :not_found
      else :unavailable
      end
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError
      :unavailable
    end

    def url = "#{BASE_URL}/novel/#{ERB::Util.url_encode(@slug)}"

    private

    def status_code
      uri = URI(url)
      response = Net::HTTP.start(uri.host, uri.port, **CONNECTION) do |http|
        http.request(Net::HTTP::Get.new(uri, 'Accept' => 'application/json'))
      end
      response.code
    end
  end
end

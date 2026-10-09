# frozen_string_literal: true

require 'test_helper'

module Api
  class UrlGuardTest < ActiveSupport::TestCase
    test 'private and local targets are refused' do
      urls = %w[
        http://127.0.0.1/x
        http://169.254.169.254/latest
        http://10.1.2.3/x
        http://192.168.0.1/x
        http://172.16.0.1/x
        http://0.0.0.0/x
        http://[::1]/x
        http://[fc00::1]/x
        http://[fe80::1]/x
        http://[::ffff:127.0.0.1]/x
        http://localhost/x
        http://metadata.google.internal/computeMetadata/v1/
        file:///etc/passwd
        http://user:pass@example.com/x
      ]

      assert_equal(['unsafe_url'] * urls.size, urls.map { |url| refusal(url) })
    end

    test 'a public address is kept' do
      assert_equal '93.184.216.34', UrlGuard.public_address!('93.184.216.34').to_s
    end

    test 'a name that resolves to a private address is refused' do
      Resolv.stub(:getaddresses, ['93.184.216.34', '10.0.0.1']) do
        error = assert_raises(Error) { UrlGuard.public_address!('cdn.example') }

        assert_equal 'unsafe_url', error.code
      end
    end

    private

    def refusal(url)
      uri = UrlGuard.uri!(url)
      UrlGuard.public_address!(uri.host)
      nil
    rescue Error => e
      e.code
    end
  end
end

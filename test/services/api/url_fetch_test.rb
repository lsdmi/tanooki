# frozen_string_literal: true

require 'test_helper'

module Api
  class UrlFetchTest < ActiveSupport::TestCase
    test 'bytes are read from the resolved address' do
      seen = nil
      Resolv.stub(:getaddresses, ['93.184.216.34']) do
        UrlFetch.stub(:http_get, lambda { |_uri, address|
          seen = address.to_s
          UrlFetch::Response.new('200', nil, 'webp')
        }) do
          assert_equal 'webp', UrlFetch.bytes('https://cdn.example/a.webp')
        end
      end

      assert_equal '93.184.216.34', seen
    end

    test 'a redirect onto a private address is not fetched' do
      calls = []
      Resolv.stub(:getaddresses, ['93.184.216.34']) do
        UrlFetch.stub(:http_get, lambda { |uri, address|
          calls << [uri.host, address.to_s]
          UrlFetch::Response.new('302', 'http://127.0.0.1/secret', nil)
        }) do
          error = assert_raises(Error) { UrlFetch.bytes('https://cdn.example/a.png') }

          assert_equal 'unsafe_url', error.code
        end
      end

      assert_equal [['cdn.example', '93.184.216.34']], calls
    end

    test 'a body over the cap is refused' do
      error = assert_raises(Error) { UrlFetch.read_body(Chunk.new('12345'), limit: 4) }

      assert_equal 'image_too_large', error.code
    end

    # Yields one chunk, the way Net::HTTP hands the body to read_body.
    class Chunk
      def initialize(payload)
        @payload = payload
      end

      def read_body
        yield @payload
      end
    end
  end
end

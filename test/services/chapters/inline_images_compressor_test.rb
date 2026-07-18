# frozen_string_literal: true

require 'test_helper'

module Chapters
  class InlineImagesCompressorTest < ActiveSupport::TestCase
    TINY_PNG_B64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

    test 'compress shrinks oversized inline data uri images' do
      encoded = Base64.strict_encode64('x' * 350.kilobytes)
      html = %(<p><img src="data:image/png;base64,#{encoded}"></p>)
      jpeg = Base64.decode64(TINY_PNG_B64)

      Chapters::InlineImageOptimizer.stub(:optimize_data_uri_in_html, [jpeg, 'jpg']) do
        result = InlineImagesCompressor.compress(html)

        assert_equal 1, result.images_compressed
        assert_operator result.after_bytes, :<, result.before_bytes
        assert_includes result.html, 'data:image/jpeg;base64,'
      end
    end

    test 'compress leaves non-data-uri images unchanged' do
      html = %(<p><img src="https://example.com/a.png"></p>)

      result = InlineImagesCompressor.compress(html)

      assert_equal 0, result.images_compressed
      assert_equal html, result.html
    end

    test 'compress skips inline images already under the size cap' do
      html = %(<p><img src="data:image/png;base64,#{TINY_PNG_B64}"></p>)

      result = InlineImagesCompressor.compress(html)

      assert_equal 0, result.images_compressed
      assert_equal html, result.html
    end
  end
end

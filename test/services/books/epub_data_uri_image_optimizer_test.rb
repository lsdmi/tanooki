# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubDataUriImageOptimizerTest < ActiveSupport::TestCase
    TINY_PNG_B64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
    TINY_PNG = Base64.decode64(TINY_PNG_B64)
    TINY_DATA_URI = "data:image/png;base64,#{TINY_PNG_B64}".freeze

    test 'optimize_data_uri returns jpeg when libvips is available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      binary, extension = EpubDataUriImageOptimizer.optimize_data_uri(TINY_DATA_URI)

      assert_equal 'jpg', extension
      assert_operator binary.bytesize, :>, 0
      assert_equal [0xFF, 0xD8], binary.bytes.first(2)
    end

    test 'optimize_data_uri keeps small originals when libvips is unavailable' do
      Attachments::VariantProcessing.stub(:available?, false) do
        binary, extension = EpubDataUriImageOptimizer.optimize_data_uri(TINY_DATA_URI)

        assert_equal TINY_PNG, binary
        assert_equal 'png', extension
      end
    end

    test 'optimize_data_uri_in_html decodes without building the full payload string' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      html = %(<img src="#{TINY_DATA_URI}">)
      src_start = html.index(TINY_DATA_URI)
      src_end = src_start + TINY_DATA_URI.length

      binary, extension = EpubDataUriImageOptimizer.optimize_data_uri_in_html(html, src_start, src_end)

      assert_equal 'jpg', extension
      assert_operator binary.bytesize, :>, 0
    end

    test 'optimize_data_uri drops large originals when shrink fails' do
      Attachments::VariantProcessing.stub(:available?, true) do
        EpubDataUriImageOptimizer.stub(:compress_file, nil) do
          large_uri = "data:image/png;base64,#{Base64.strict_encode64('x' * 200.kilobytes)}"
          binary, extension = EpubDataUriImageOptimizer.optimize_data_uri(large_uri)

          assert_nil binary
          assert_nil extension
        end
      end
    end
  end
end

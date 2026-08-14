# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressInlineImagesTest < ActiveSupport::TestCase
    setup do
      @rich_text = action_text_rich_texts(:rich_text_four)
      encoded = Base64.strict_encode64('x' * 350.kilobytes)
      @rich_text.update!(body: %(<p><img src="data:image/png;base64,#{encoded}"></p>))
      @jpeg = Base64.decode64(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
      )
    end

    test 'call compresses inline images in chapter rich text body' do
      with_compression_stub do
        result = CompressInlineImages.call(chapters(:one).id)

        assert_equal 1, result.images_compressed
        assert_not result.unchanged
      end
    end

    test 'call rewrites compressed image as jpeg data uri' do
      with_compression_stub do
        CompressInlineImages.call(chapters(:one).id)
        body = @rich_text.reload.read_attribute_before_type_cast(:body)

        assert_includes body, 'data:image/jpeg;base64,'
      end
    end

    test 'call reduces rich text body size' do
      with_compression_stub do
        result = CompressInlineImages.call(chapters(:one).id)

        assert_operator result.after_bytes, :<, result.before_bytes
      end
    end

    test 'call skips bodies over the automated size limit' do
      with_compression_stub do
        result = CompressInlineImages.call(chapters(:one).id, max_body_bytes: 100)

        assert_equal :body_too_large, result.skipped_reason
      end
    end

    test 'call leaves an oversized body untouched' do
      before = @rich_text.reload.read_attribute_before_type_cast(:body)

      with_compression_stub do
        CompressInlineImages.call(chapters(:one).id, max_body_bytes: 100)

        assert_equal before, @rich_text.reload.read_attribute_before_type_cast(:body)
      end
    end

    test 'call compresses an oversized body when the limit is disabled' do
      with_compression_stub do
        result = CompressInlineImages.call(chapters(:one).id, max_body_bytes: nil)

        assert_equal 1, result.images_compressed
      end
    end

    private

    def with_compression_stub(&)
      Chapters::InlineImageOptimizer.stub(:optimize_data_uri_in_html, [@jpeg, 'jpg']) do
        Attachments::VariantProcessing.stub(:available?, true, &)
      end
    end
  end
end

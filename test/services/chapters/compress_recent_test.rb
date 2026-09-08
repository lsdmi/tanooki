# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressRecentTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @rich_text = action_text_rich_texts(:rich_text_four)
      @jpeg = Base64.decode64(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
      )
    end

    test 'call compresses chapters posted on the previous day' do
      write_compressible_body

      result = with_compression_stub { CompressRecent.call(day: day_after_chapter) }

      assert_equal [@chapter.id], result.chapter_ids
      assert_equal 1, result.compressed
      assert_empty result.errors
    end

    test 'call reports unchanged when no images need compression' do
      @rich_text.update!(body: '<p>no images</p>')

      result = with_compression_stub { CompressRecent.call(day: day_after_chapter) }

      assert_equal [@chapter.id], result.chapter_ids
      assert_equal 1, result.unchanged
      assert_equal 0, result.compressed
    end

    private

    def write_compressible_body
      encoded = Base64.strict_encode64('x' * 350.kilobytes)
      @rich_text.update!(body: %(<p><img src="data:image/png;base64,#{encoded}"></p>))
    end

    # The service compresses the day before the one it is given, so aim it at the day after @chapter went public.
    def day_after_chapter
      @chapter.public_at.to_date.next_day
    end

    def with_compression_stub(&)
      InlineImageOptimizer.stub(:optimize_data_uri_in_html, [@jpeg, 'jpg']) do
        Attachments::VariantProcessing.stub(:available?, true, &)
      end
    end
  end
end

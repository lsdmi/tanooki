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
      travel_to Time.zone.parse('2026-07-19 04:00:00') do
        stamp(@chapter, published_at: '2026-07-18 12:00')
        write_compressible_body
        stamp(chapters(:two), published_at: '2026-07-16 12:00')

        result = with_compression_stub do
          CompressRecent.call(day: Date.parse('2026-07-19'))
        end

        assert_equal [@chapter.id], result.chapter_ids
        assert_equal 1, result.compressed
        assert_empty result.errors
      end
    end

    test 'call reports unchanged when no images need compression' do
      travel_to Time.zone.parse('2026-07-19 04:00:00') do
        stamp(@chapter, published_at: '2026-07-18 12:00')
        @rich_text.update!(body: '<p>no images</p>')

        result = with_compression_stub do
          CompressRecent.call(day: Date.parse('2026-07-19'))
        end

        assert_equal [@chapter.id], result.chapter_ids
        assert_equal 1, result.unchanged
        assert_equal 0, result.compressed
      end
    end

    private

    def write_compressible_body
      encoded = Base64.strict_encode64('x' * 350.kilobytes)
      @rich_text.update!(body: %(<p><img src="data:image/png;base64,#{encoded}"></p>))
    end

    def stamp(chapter, published_at:)
      chapter.update_columns( # rubocop:disable Rails/SkipsModelValidations
        published_at: Time.zone.parse(published_at),
        created_at: Time.zone.parse(published_at)
      )
    end

    def with_compression_stub(&)
      InlineImageOptimizer.stub(:optimize_data_uri_in_html, [@jpeg, 'jpg']) do
        Attachments::VariantProcessing.stub(:available?, true, &)
      end
    end
  end
end

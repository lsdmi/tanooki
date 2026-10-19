# frozen_string_literal: true

require 'test_helper'

module Meta
  class CoverCardPresetsTest < ActiveSupport::TestCase
    test 'card webp keeps high quality and strips metadata' do
      avif, webp = CoverCardPresets.transformations_for(:card)

      assert_equal 88, webp.dig(:saver, :quality)
      assert_equal 80, avif.dig(:saver, :quality)
      assert webp.dig(:saver, :strip)
    end

    test 'thumb webp uses a smaller limit and lower quality than card' do
      _thumb_avif, thumb_webp = CoverCardPresets.transformations_for(:thumb)

      assert_equal 65, thumb_webp.dig(:saver, :quality)
      assert_equal [160, 240], thumb_webp[:resize_to_limit]
    end
  end
end

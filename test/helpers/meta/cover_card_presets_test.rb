# frozen_string_literal: true

require 'test_helper'

module Meta
  class CoverCardPresetsTest < ActiveSupport::TestCase
    test 'card webp resizes without a custom saver' do
      _avif, webp = CoverCardPresets.transformations_for(:card)

      assert_equal [400, 600], webp[:resize_to_limit]
      assert_equal :webp, webp[:format]
      assert_nil webp[:saver]
    end

    test 'card avif resizes without a custom saver' do
      avif, _webp = CoverCardPresets.transformations_for(:card)

      assert_equal :avif, avif[:format]
      assert_nil avif[:saver]
    end

    test 'thumb transformations use a smaller limit than card' do
      _thumb_avif, thumb_webp = CoverCardPresets.transformations_for(:thumb)

      assert_equal [160, 240], thumb_webp[:resize_to_limit]
      assert_nil thumb_webp[:saver]
    end
  end
end

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

    test 'card srcset widths keep the same aspect ladder' do
      assert_equal [200, 280, 400], CoverCardPresets::CARD_SRCSET_WIDTHS

      transform = CoverCardPresets.card_transformations_for_width(200, format: :webp)

      assert_equal [200, 300], transform[:resize_to_limit]
      assert_equal :webp, transform[:format]
    end

    test 'thumb srcset widths keep the same aspect ladder' do
      assert_equal [80, 120, 160], CoverCardPresets::THUMB_SRCSET_WIDTHS

      transform = CoverCardPresets.thumb_transformations_for_width(80, format: :avif)

      assert_equal [80, 120], transform[:resize_to_limit]
      assert_equal :avif, transform[:format]
    end
  end
end

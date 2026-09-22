# frozen_string_literal: true

require 'test_helper'

module Meta
  class CoverCardThumbPresetTest < ActionView::TestCase
    include CoverUrlsHelper
    include Rails.application.routes.url_helpers

    setup do
      @fiction = fictions(:one)
    end

    test 'cover_card_picture_tag accepts a thumb preset for list tiles' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      Attachments::ImageDimensions.stub(:from_blob, [600, 800]) do
        html = cover_card_picture_tag(@fiction.cover, preset: :thumb, alt: 'Cover', class: 'cover-card')

        assert_match %r{<picture>.*type="image/avif".*type="image/webp".*class="cover-card"}m, html
        assert_match(/width="160"/, html)
        assert_match(/height="213"/, html)
      end
    end
  end
end

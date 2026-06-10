# frozen_string_literal: true

require 'test_helper'

module Meta
  class CoverUrlsHelperTest < ActionView::TestCase
    include CoverUrlsHelper
    include Rails.application.routes.url_helpers

    setup do
      @fiction = fictions(:one)
    end

    test 'cover_card_url returns a representation url for raster covers when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      assert_predicate @fiction.cover.blob, :variable?

      assert_includes cover_card_url(@fiction.cover), '/rails/active_storage/representations'
    end

    test 'cover_background_url returns a representation url for raster covers when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      assert_predicate @fiction.cover.blob, :variable?

      assert_includes cover_background_url(@fiction.cover), '/rails/active_storage/representations'
    end

    test 'cover_card_url falls back to blob url when variant processing is unavailable' do
      Attachments::VariantProcessing.stub(:available?, false) do
        assert_predicate @fiction.cover.blob, :variable?
        assert_includes cover_card_url(@fiction.cover), '/rails/active_storage/blobs'
      end
    end

    test 'cover_card_url falls back to blob url for svg covers' do
      @fiction.cover.attach(
        io: Rails.root.join('app/assets/images/logo-default.svg').open,
        filename: 'logo-default.svg',
        content_type: 'image/svg+xml'
      )

      assert_not_predicate @fiction.cover.blob, :variable?
      assert_includes cover_card_url(@fiction.cover), '/rails/active_storage/blobs'
    end
  end
end

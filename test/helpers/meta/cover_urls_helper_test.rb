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

    test 'cover_card_avif_url returns an avif representation when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      assert_includes cover_card_avif_url(@fiction.cover), '/rails/active_storage/representations'
    end

    test 'cover_card_picture_tag accepts a featured preset for larger editorial tiles' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      html = cover_card_picture_tag(@fiction.cover, preset: :featured, alt: 'Cover', class: 'cover-card')

      assert_match %r{<picture>.*type="image/avif".*type="image/webp".*class="cover-card"}m, html
    end

    test 'cover_card_picture_tag accepts a wide preset for 16:9 tiles' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      html = cover_card_picture_tag(@fiction.cover, preset: :wide, alt: 'Cover', class: 'cover-card')

      assert_match %r{<picture>.*type="image/avif".*type="image/webp"}m, html
    end

    test 'cover_card_picture_tag renders avif and webp sources when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      html = cover_card_picture_tag(@fiction.cover, alt: 'Cover', class: 'cover-card')

      assert_match %r{<picture>.*type="image/avif".*type="image/webp".*class="cover-card"}m, html
    end

    test 'cover_card_picture_tag includes width and height matching the card variant' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      Attachments::ImageDimensions.stub(:from_blob, [600, 800]) do
        html = cover_card_picture_tag(@fiction.cover, alt: 'Cover', class: 'cover-card')

        assert_match(/width="400"/, html)
        assert_match(/height="533"/, html)
      end
    end

    test 'cover_card_picture_tag preserves explicit width and height overrides' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      html = cover_card_picture_tag(@fiction.cover, alt: 'Cover', width: 120, height: 180)

      assert_match(/width="120"/, html)
      assert_match(/height="180"/, html)
    end

    test 'cover_card_picture_tag defers sources when lazy' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      html = cover_card_picture_tag(@fiction.cover, alt: 'Cover', lazy: true, id: 'cover-image')

      assert html.include?('data-srcset=') && html.include?('data-url=') && html.include?('id="cover-image"')
    end

    test 'cover_background_url returns a representation url for raster covers when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      assert_predicate @fiction.cover.blob, :variable?

      assert_includes cover_background_url(@fiction.cover), '/rails/active_storage/representations'
    end

    test 'banner_showcase_url returns a representation url for raster banners when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?
      skip 'fiction fixture has no banner' unless @fiction.banner.attached?

      assert_predicate @fiction.banner.blob, :variable?

      assert_includes banner_showcase_url(@fiction.banner), '/rails/active_storage/representations'
    end

    test 'avatar_image_url returns a representation url when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      assert_includes avatar_image_url(@fiction.cover), '/rails/active_storage/representations'
    end

    test 'publication_cover_header_url returns a representation url when variants are available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      assert_includes publication_cover_header_url(@fiction.cover), '/rails/active_storage/representations'
    end

    test 'cover_card_url falls back to blob url when variant processing is unavailable' do
      Attachments::VariantProcessing.stub(:available?, false) do
        assert_predicate @fiction.cover.blob, :variable?
        assert_includes cover_card_url(@fiction.cover), '/rails/active_storage/blobs'
      end
    end

    test 'cover_card_url falls back to blob url for svg covers' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join('app/assets/images/logo-default.svg').open,
        filename: 'logo-default.svg',
        content_type: 'image/svg+xml'
      )
      @fiction.cover.attach(blob)

      assert_not_predicate @fiction.cover.blob, :variable?
      assert_includes cover_card_url(@fiction.cover), '/rails/active_storage/blobs'
    end
  end
end

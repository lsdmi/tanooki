# frozen_string_literal: true

module Meta
  # Resized cover URLs for list, card, and blurred page backgrounds.
  module CoverUrlsHelper
    include CoverCardPictureHelper
    include CoverCardDimensionsHelper

    PUBLICATION_HEADER_TRANSFORMATIONS = { resize_to_limit: [1600, 600], format: :webp }.freeze
    BACKGROUND_TRANSFORMATIONS = { resize_to_limit: [1280, 1920], format: :webp }.freeze
    SHOWCASE_SIZE = [1600, 540].freeze
    SHOWCASE_MOBILE_SIZE = [768, 320].freeze
    SHOWCASE_TRANSFORMATIONS = { resize_to_limit: SHOWCASE_SIZE, format: :webp }.freeze
    SHOWCASE_MOBILE_TRANSFORMATIONS = { resize_to_limit: SHOWCASE_MOBILE_SIZE, format: :webp }.freeze
    AVATAR_TRANSFORMATIONS = { resize_to_limit: [128, 128], format: :webp }.freeze
    SCANLATOR_AVATAR_TRANSFORMATIONS = { resize_to_limit: [256, 256], format: :webp }.freeze
    VIDEO_THUMB_TRANSFORMATIONS = { resize_to_limit: [640, 360], format: :webp }.freeze

    def cover_card_url(attachment)
      urls = cover_card_variant_urls(attachment)
      urls[:webp] || urls[:fallback]
    end

    def cover_card_avif_url(attachment)
      cover_card_variant_urls(attachment)[:avif]
    end

    def cover_thumbnail_url(attachment)
      variant_image_url(attachment, CoverCardPresets::THUMB_TRANSFORMATIONS)
    end

    def cover_background_url(attachment)
      variant_image_url(attachment, BACKGROUND_TRANSFORMATIONS)
    end

    def banner_showcase_url(attachment, size: :desktop)
      variant_image_url(attachment, showcase_transformations_for(size))
    end

    def banner_showcase_mobile_dimensions
      SHOWCASE_MOBILE_SIZE
    end

    def avatar_image_url(attachment)
      variant_image_url(attachment, AVATAR_TRANSFORMATIONS)
    end

    def scanlator_avatar_url(attachment)
      return asset_path('scanlator_avatar.webp') unless attachment&.attached?

      variant_image_url(attachment, SCANLATOR_AVATAR_TRANSFORMATIONS) || asset_path('scanlator_avatar.webp')
    end

    def scanlator_banner_url(attachment)
      return asset_path('scanlator_banner.webp') unless attachment&.attached?

      variant_image_url(attachment, SHOWCASE_TRANSFORMATIONS) || asset_path('scanlator_banner.webp')
    end

    def publication_cover_header_url(attachment)
      variant_image_url(attachment, PUBLICATION_HEADER_TRANSFORMATIONS)
    end

    def video_thumbnail_url(thumbnail)
      return thumbnail if thumbnail.is_a?(String)

      variant_image_url(thumbnail, VIDEO_THUMB_TRANSFORMATIONS)
    end

    private

    def cover_card_variant_urls(attachment, preset: :card)
      return {} unless attachment&.attached?
      return { fallback: url_for(attachment) } unless variable_cover?(attachment)

      avif_transform, webp_transform = CoverCardPresets.transformations_for(preset)

      {
        avif: url_for(attachment.variant(avif_transform)),
        webp: url_for(attachment.variant(webp_transform))
      }
    rescue ActiveStorage::Error
      { fallback: url_for(attachment) }
    end

    def showcase_transformations_for(size)
      size.to_sym == :mobile ? SHOWCASE_MOBILE_TRANSFORMATIONS : SHOWCASE_TRANSFORMATIONS
    end

    def variable_cover?(attachment)
      attachment.blob.variable? && Attachments::VariantProcessing.available?
    end

    def variant_image_url(attachment, transformations)
      return unless attachment&.attached?

      if attachment.blob.variable? && Attachments::VariantProcessing.available?
        url_for(attachment.variant(transformations))
      else
        url_for(attachment)
      end
    rescue ActiveStorage::Error
      url_for(attachment)
    end
  end
end

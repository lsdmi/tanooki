# frozen_string_literal: true

module Meta
  # Resized cover URLs for list, card, and blurred page backgrounds.
  module CoverUrlsHelper
    CARD_TRANSFORMATIONS = { resize_to_limit: [400, 600], format: :webp }.freeze
    THUMB_TRANSFORMATIONS = { resize_to_limit: [160, 240], format: :webp }.freeze
    BACKGROUND_TRANSFORMATIONS = { resize_to_limit: [1280, 1920], format: :webp }.freeze
    SHOWCASE_TRANSFORMATIONS = { resize_to_limit: [1600, 540], format: :webp }.freeze
    AVATAR_TRANSFORMATIONS = { resize_to_limit: [128, 128], format: :webp }.freeze
    SCANLATOR_AVATAR_TRANSFORMATIONS = { resize_to_limit: [256, 256], format: :webp }.freeze
    PUBLICATION_HEADER_TRANSFORMATIONS = { resize_to_limit: [1600, 600], format: :webp }.freeze
    AD_POSTER_TRANSFORMATIONS = { resize_to_limit: [1280, 720], format: :webp }.freeze
    VIDEO_THUMB_TRANSFORMATIONS = { resize_to_limit: [640, 360], format: :webp }.freeze

    def cover_card_url(attachment)
      variant_image_url(attachment, CARD_TRANSFORMATIONS)
    end

    def cover_thumbnail_url(attachment)
      variant_image_url(attachment, THUMB_TRANSFORMATIONS)
    end

    def cover_background_url(attachment)
      variant_image_url(attachment, BACKGROUND_TRANSFORMATIONS)
    end

    def banner_showcase_url(attachment)
      variant_image_url(attachment, SHOWCASE_TRANSFORMATIONS)
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

    def advertisement_poster_url(attachment)
      variant_image_url(attachment, AD_POSTER_TRANSFORMATIONS)
    end

    def video_thumbnail_url(thumbnail)
      return thumbnail if thumbnail.is_a?(String)

      variant_image_url(thumbnail, VIDEO_THUMB_TRANSFORMATIONS)
    end

    private

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

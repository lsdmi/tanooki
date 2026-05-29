# frozen_string_literal: true

module Attachments
  # Resized cover URLs for list and card views (full blobs stay on detail/hero pages).
  module CoverVariantsHelper
    CARD_TRANSFORMATIONS = { resize_to_limit: [400, 600], format: :webp }.freeze
    THUMB_TRANSFORMATIONS = { resize_to_limit: [160, 240], format: :webp }.freeze

    def cover_card_url(attachment)
      variant_image_url(attachment, CARD_TRANSFORMATIONS)
    end

    def cover_thumbnail_url(attachment)
      variant_image_url(attachment, THUMB_TRANSFORMATIONS)
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

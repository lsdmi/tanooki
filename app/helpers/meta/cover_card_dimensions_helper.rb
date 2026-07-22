# frozen_string_literal: true

module Meta
  # Computes display width/height for cover card <picture> tags from blob metadata.
  module CoverCardDimensionsHelper
    def cover_card_display_dimensions(attachment, preset: :card)
      return unless attachment&.attached?

      source = Attachments::ImageDimensions.from_blob(attachment.blob)
      return unless source

      if variable_cover?(attachment)
        resize_to_limit_dimensions(*source, *cover_card_limit_for_preset(preset))
      else
        source
      end
    end

    private

    def cover_card_limit_for_preset(preset)
      case preset.to_sym
      when :featured
        CoverUrlsHelper::FEATURED_CARD_SIZE
      when :wide
        CoverUrlsHelper::WIDE_CARD_SIZE
      else
        CoverUrlsHelper::CARD_SIZE
      end
    end

    def resize_to_limit_dimensions(width, height, max_width, max_height)
      return unless width.to_i.positive? && height.to_i.positive?

      width = width.to_i
      height = height.to_i
      scale = [max_width.to_f / width, max_height.to_f / height].min
      return [width, height] if scale >= 1

      [(width * scale).round, (height * scale).round]
    end
  end
end

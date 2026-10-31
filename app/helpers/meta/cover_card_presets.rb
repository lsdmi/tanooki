# frozen_string_literal: true

module Meta
  # Size and AVIF/WebP transformation pairs for cover_card_picture_tag presets.
  module CoverCardPresets
    CARD_SIZE = [400, 600].freeze
    # Same quality ladder for responsive <source srcset> — widths only, no saver/quality drop.
    CARD_SRCSET_WIDTHS = [200, 280, 400].freeze
    FEATURED_CARD_SIZE = [1280, 960].freeze
    WIDE_CARD_SIZE = [1280, 720].freeze
    THUMB_SIZE = [160, 240].freeze

    CARD_WEBP_TRANSFORMATIONS = { resize_to_limit: CARD_SIZE, format: :webp }.freeze
    CARD_AVIF_TRANSFORMATIONS = { resize_to_limit: CARD_SIZE, format: :avif }.freeze
    FEATURED_CARD_WEBP_TRANSFORMATIONS = { resize_to_limit: FEATURED_CARD_SIZE, format: :webp }.freeze
    FEATURED_CARD_AVIF_TRANSFORMATIONS = { resize_to_limit: FEATURED_CARD_SIZE, format: :avif }.freeze
    WIDE_CARD_WEBP_TRANSFORMATIONS = { resize_to_limit: WIDE_CARD_SIZE, format: :webp }.freeze
    WIDE_CARD_AVIF_TRANSFORMATIONS = { resize_to_limit: WIDE_CARD_SIZE, format: :avif }.freeze
    THUMB_WEBP_TRANSFORMATIONS = { resize_to_limit: THUMB_SIZE, format: :webp }.freeze
    THUMB_AVIF_TRANSFORMATIONS = { resize_to_limit: THUMB_SIZE, format: :avif }.freeze
    CARD_TRANSFORMATIONS = CARD_WEBP_TRANSFORMATIONS
    THUMB_TRANSFORMATIONS = THUMB_WEBP_TRANSFORMATIONS

    # Storage gallery: 2→6 columns. List row covers stay ~7–8rem.
    CARD_GRID_SIZES = '(max-width: 639px) 45vw, (max-width: 767px) 30vw, (max-width: 1279px) 22vw, 180px'
    CARD_LIST_SIZES = '(max-width: 639px) 7rem, 8rem'

    PRESET_TRANSFORMATIONS = {
      card: [CARD_AVIF_TRANSFORMATIONS, CARD_WEBP_TRANSFORMATIONS].freeze,
      featured: [FEATURED_CARD_AVIF_TRANSFORMATIONS, FEATURED_CARD_WEBP_TRANSFORMATIONS].freeze,
      wide: [WIDE_CARD_AVIF_TRANSFORMATIONS, WIDE_CARD_WEBP_TRANSFORMATIONS].freeze,
      thumb: [THUMB_AVIF_TRANSFORMATIONS, THUMB_WEBP_TRANSFORMATIONS].freeze
    }.freeze

    PRESET_SIZES = {
      card: CARD_SIZE,
      featured: FEATURED_CARD_SIZE,
      wide: WIDE_CARD_SIZE,
      thumb: THUMB_SIZE
    }.freeze

    module_function

    def transformations_for(preset)
      PRESET_TRANSFORMATIONS.fetch(preset.to_sym, PRESET_TRANSFORMATIONS[:card])
    end

    def size_for(preset)
      PRESET_SIZES.fetch(preset.to_sym, PRESET_SIZES[:card])
    end

    def card_srcset_size(width)
      height = (width * CARD_SIZE[1] / CARD_SIZE[0].to_f).round
      [width, height]
    end

    def card_transformations_for_width(width, format:)
      { resize_to_limit: card_srcset_size(width), format: format }
    end
  end
end

# frozen_string_literal: true

module Meta
  # Size and AVIF/WebP transformation pairs for cover_card_picture_tag presets.
  module CoverCardPresets
    CARD_SIZE = [400, 600].freeze
    FEATURED_CARD_SIZE = [1280, 960].freeze
    WIDE_CARD_SIZE = [1280, 720].freeze
    THUMB_SIZE = [160, 240].freeze

    # Strip metadata; quality tuned for card/list tiles (PSI image-delivery on show).
    WEBP_SAVER = { quality: 72, strip: true }.freeze
    AVIF_SAVER = { quality: 65, strip: true }.freeze
    THUMB_WEBP_SAVER = { quality: 65, strip: true }.freeze
    THUMB_AVIF_SAVER = { quality: 55, strip: true }.freeze

    CARD_WEBP_TRANSFORMATIONS = { resize_to_limit: CARD_SIZE, format: :webp, saver: WEBP_SAVER }.freeze
    CARD_AVIF_TRANSFORMATIONS = { resize_to_limit: CARD_SIZE, format: :avif, saver: AVIF_SAVER }.freeze
    FEATURED_CARD_WEBP_TRANSFORMATIONS = {
      resize_to_limit: FEATURED_CARD_SIZE, format: :webp, saver: WEBP_SAVER
    }.freeze
    FEATURED_CARD_AVIF_TRANSFORMATIONS = {
      resize_to_limit: FEATURED_CARD_SIZE, format: :avif, saver: AVIF_SAVER
    }.freeze
    WIDE_CARD_WEBP_TRANSFORMATIONS = { resize_to_limit: WIDE_CARD_SIZE, format: :webp, saver: WEBP_SAVER }.freeze
    WIDE_CARD_AVIF_TRANSFORMATIONS = { resize_to_limit: WIDE_CARD_SIZE, format: :avif, saver: AVIF_SAVER }.freeze
    THUMB_WEBP_TRANSFORMATIONS = { resize_to_limit: THUMB_SIZE, format: :webp, saver: THUMB_WEBP_SAVER }.freeze
    THUMB_AVIF_TRANSFORMATIONS = { resize_to_limit: THUMB_SIZE, format: :avif, saver: THUMB_AVIF_SAVER }.freeze
    CARD_TRANSFORMATIONS = CARD_WEBP_TRANSFORMATIONS
    THUMB_TRANSFORMATIONS = THUMB_WEBP_TRANSFORMATIONS

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
  end
end

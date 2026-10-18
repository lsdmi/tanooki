# frozen_string_literal: true

module Fictions
  # Mikai-style showcase overlay: centered title, blurb, rating/views/author, read link.
  class ShowcaseSlideOverlayComponent < ViewComponent::Base
    include Fictions::FormattingHelper
    include Layout::TurboDriveHelper
    include ShowcaseSlideOverlayComponentStyles

    LAYOUTS = %i[responsive mobile_minimal full].freeze
    BLURB_CHARS = 220

    def initialize(fiction:, editorial_kinds:, links:, **options)
      super()
      @fiction = fiction
      @editorial_kinds = editorial_kinds
      @read_href = links.fetch(:read)
      @fiction_href = links.fetch(:fiction)
      @eager_link_preload = options.fetch(:eager_link_preload, false)
      @layout = options.fetch(:layout, :responsive).to_sym
      @content_rail = options.fetch(:content_rail, true)
      validate!
    end

    private

    attr_reader :fiction, :editorial_kinds, :read_href, :fiction_href, :eager_link_preload, :layout, :content_rail

    def validate!
      raise ArgumentError, "unknown layout: #{layout}" unless LAYOUTS.include?(layout)
    end

    def rail?
      content_rail
    end

    def mobile_minimal?
      layout == :mobile_minimal
    end

    def showcase_blurb
      raw = fiction.try(:short_description).presence || fiction.try(:description).presence
      return if raw.blank?

      text = raw.to_s.squish
      return text if text.length <= BLURB_CHARS

      "#{text[0, BLURB_CHARS].rstrip}…"
    end

    def rating_label
      fiction.average_rating.positive? ? helpers.number_with_precision(fiction.average_rating, precision: 1) : '—'
    end
  end
end

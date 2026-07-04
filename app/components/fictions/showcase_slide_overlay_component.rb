# frozen_string_literal: true

module Fictions
  # Text overlay for fiction index / genre showcase carousel slides.
  # Mobile (< sm): tag, title, and description only — bottom-aligned, no metadata or CTAs.
  class ShowcaseSlideOverlayComponent < ViewComponent::Base
    include Fictions::FormattingHelper
    include Layout::TurboDriveHelper
    include ShowcaseSlideOverlayComponentStyles
    include Ui::ComponentHelper

    # :responsive — production default; mobile/desktop via max-sm: Tailwind breakpoints.
    # :mobile_minimal — Lookbook only; forces minimal mobile overlay at any viewport width.
    # :full — Lookbook only; forces desktop overlay (metadata + CTAs) at any viewport width.
    LAYOUTS = %i[responsive mobile_minimal full].freeze

    def initialize(fiction:, editorial_kinds:, links:, eager_link_preload: false, layout: :responsive)
      super()
      @fiction = fiction
      @editorial_kinds = editorial_kinds
      @read_href = links.fetch(:read)
      @fiction_href = links.fetch(:fiction)
      @eager_link_preload = eager_link_preload
      @layout = layout.to_sym
      validate!
    end

    private

    attr_reader :fiction, :editorial_kinds, :read_href, :fiction_href, :eager_link_preload, :layout

    def validate!
      raise ArgumentError, "unknown layout: #{layout}" unless LAYOUTS.include?(layout)
    end

    def mobile_minimal?
      layout == :mobile_minimal
    end

    def full?
      layout == :full
    end

    def rating_label
      fiction.average_rating.positive? ? helpers.number_with_precision(fiction.average_rating, precision: 1) : '—'
    end
  end
end

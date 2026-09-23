# frozen_string_literal: true

module Ui
  # Metadata tags for genre page fiction cards (rank, cover stats, chapters, status, genre).
  class GenrePageTagComponent < ViewComponent::Base
    include GenrePageTagComponentStyles

    VARIANTS = %i[rank stat_views stat_rating chapters status genre adult sixteen eighteen].freeze
    RANK_SIZES = %i[featured thumb strip].freeze
    WARNING_VARIANTS = %i[adult sixteen eighteen].freeze

    def initialize(variant:, label:, **options)
      super()
      @variant = variant.to_sym
      @label = label.to_s
      @rank_size = options.fetch(:rank_size, :thumb).to_sym
      @href = options[:href]
      @html = options.fetch(:html, {})
      validate!
    end

    def render?
      label.present?
    end

    private

    attr_reader :variant, :label, :rank_size, :href, :html

    def validate!
      raise ArgumentError, "unknown variant: #{variant}" unless VARIANTS.include?(variant)
      raise ArgumentError, "unknown rank_size: #{rank_size}" unless RANK_SIZES.include?(rank_size)
    end

    def interactive?
      variant.in?(%i[genre adult sixteen eighteen]) && href.present?
    end

    def warning_icon?
      WARNING_VARIANTS.include?(variant)
    end

    def tag_attributes
      attrs = { class: css_classes }
      attrs[:aria] = { label: "Місце в рейтингу: #{label}" } if variant == :rank
      attrs.merge!(html.except(:class))
      attrs[:class] = [attrs[:class], html[:class]].compact.join(' ')
      attrs
    end

    def css_classes
      variant == :rank ? RANK_CLASSES.fetch(rank_size) : VARIANT_CLASSES.fetch(variant)
    end

    def icon_classes
      return ADULT_ICON_CLASSES if warning_icon?

      ICON_CLASSES.fetch(variant)
    end

    def stat_variant?
      variant.in?(%i[stat_views stat_rating])
    end

    def truncate_label?
      variant == :stat_views
    end
  end
end

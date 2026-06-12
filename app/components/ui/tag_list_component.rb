# frozen_string_literal: true

module Ui
  # Flex row of taxonomy tags with wrapping.
  class TagListComponent < ViewComponent::Base
    def initialize(labels:, variant: :keyword, size: :sm, **options)
      super()
      assign_tag_list_options(labels, variant, size, options)
    end

    def render?
      labels.any?
    end

    private

    attr_reader :labels, :variant, :size, :max, :href_builder, :current_label, :counts, :genre_slugs, :html,
                :tag_html

    def variant_for(label)
      return variant unless variant == :genre

      Genre.tag_variant(name: label, slug: genre_slugs[label] || genre_slugs[label.to_s])
    end

    def adult_label?(label)
      variant_for(label) == :adult
    end

    def visible_labels
      return labels if max.nil?

      adults, regular = partitioned_labels
      remaining = max

      visible_adults = adults.first(remaining)
      remaining -= visible_adults.size

      visible_adults + regular.first(remaining)
    end

    def overflow_count
      return 0 if max.nil?

      labels.size - visible_labels.size
    end

    def tag_groups
      adults, regular = visible_labels.partition { |label| adult_label?(label) }
      groups = []
      groups << { type: :adult_cluster, labels: adults } if adults.any?
      regular.each { |label| groups << { type: :single, label: label } }
      groups
    end

    def partitioned_labels
      labels.partition { |label| adult_label?(label) }
    end

    def render_tag(label)
      tag_href = href_for(label)
      render Ui::TagComponent.new(
        label: label,
        variant: variant_for(label),
        size: size,
        as: tag_href.present? ? :link : :span,
        href: tag_href,
        current: current?(label),
        count: count_for(label),
        html: tag_html
      )
    end

    def wrapper_classes
      wrap = html[:class].to_s.include?('nowrap') ? 'flex-nowrap' : 'flex-wrap'

      ['flex items-center gap-2', wrap, html[:class]].compact.join(' ')
    end

    def href_for(label)
      return unless href_builder

      href_builder.call(label)
    end

    def current?(label)
      current_label.present? && current_label.to_s == label.to_s
    end

    def count_for(label)
      value = counts[label] || counts[label.to_s]
      value.to_i.positive? ? value.to_i : nil
    end

    def assign_tag_list_options(labels, variant, size, options)
      assign_tag_list_core(labels, variant, size, options)
      assign_tag_list_presentation(options)
    end

    def assign_tag_list_core(labels, variant, size, options)
      @genre_slugs = options.fetch(:genre_slugs, {}).to_h
      @labels = Array(labels).compact_blank
      @labels = Genre.sort_labels_adult_first(@labels, slugs: @genre_slugs) if options[:sort_adult_first]
      @variant = variant
      @size = size
      @max = options[:max]
    end

    def assign_tag_list_presentation(options)
      @href_builder = options[:href_builder]
      @current_label = options[:current_label]
      @counts = options.fetch(:counts, {}).to_h
      @html = options.fetch(:html, {})
      @tag_html = options.fetch(:tag_html, {})
    end
  end
end

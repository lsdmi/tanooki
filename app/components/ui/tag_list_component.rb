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

    def visible_labels
      return labels if max.nil? || labels.size <= max

      labels.first(max)
    end

    def overflow_count
      return 0 if max.nil? || labels.size <= max

      labels.size - max
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

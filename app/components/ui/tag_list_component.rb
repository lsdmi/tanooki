# frozen_string_literal: true

module Ui
  # Flex row of taxonomy tags with wrapping.
  class TagListComponent < ViewComponent::Base
    def initialize(labels:, variant: :keyword, size: :sm, **options)
      super()
      @labels = Array(labels).compact_blank
      @variant = variant
      @size = size
      @href_builder = options[:href_builder]
      @current_label = options[:current_label]
      @counts = options.fetch(:counts, {}).to_h
      @html = options.fetch(:html, {})
    end

    def render?
      labels.any?
    end

    private

    attr_reader :labels, :variant, :size, :href_builder, :current_label, :counts, :html

    def wrapper_classes
      ['flex flex-wrap items-center gap-2', html[:class]].compact.join(' ')
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
  end
end

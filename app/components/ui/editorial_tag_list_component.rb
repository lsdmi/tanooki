# frozen_string_literal: true

module Ui
  # Renders up to HERO_MAX editorial tags for hero banners.
  class EditorialTagListComponent < ViewComponent::Base
    def initialize(kinds:, max: EditorialTagComponent::HERO_MAX, labels: {}, html: {})
      super()
      @kinds = kinds
      @max = max
      @labels = labels
      @html = html
    end

    def render?
      kinds.any?
    end

    private

    attr_reader :kinds, :max, :labels, :html

    def visible_kinds
      kinds.first(max)
    end

    def wrapper_classes
      ['flex flex-wrap items-center gap-2', html[:class]].compact.join(' ')
    end

    def label_for(kind)
      labels[kind] || labels[kind.to_sym]
    end
  end
end

# frozen_string_literal: true

module Ui
  # Fiction tags (themes, tropes) as text under a caption: `Теґи #Переродження #ЛітРПГ`.
  # Quieter than genre chips. A tag is a link to the catalogue filter when `href_builder` returns a path for it.
  # An 18+ tag keeps its place in the text but gets the warning icon and the danger colour.
  class TextTagListComponent < ViewComponent::Base
    CAPTION_CLASSES = 'text-fg-muted'
    ITEM_CLASSES = 'text-fg-secondary'
    ADULT_ITEM_CLASSES = 'inline-flex items-center gap-1 font-medium text-status-danger-solid'
    ICON_CLASSES = 'h-3.5 w-3.5 shrink-0'
    LIST_CLASSES = 'flex flex-wrap gap-x-3 gap-y-1 text-sm/6'
    LINK_CLASSES = 'rounded-sm underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 ' \
                   'focus-visible:ring-line-strong'

    def initialize(labels:, caption:, explicit_labels: [], href_builder: nil)
      super()
      @labels = Array(labels).compact_blank
      @caption = caption
      @explicit_labels = Array(explicit_labels).map(&:to_s)
      @href_builder = href_builder
    end

    def render?
      labels.any?
    end

    private

    attr_reader :labels, :caption, :explicit_labels, :href_builder

    def adult?(label)
      explicit_labels.include?(label.to_s)
    end

    def item_classes(label)
      adult?(label) ? ADULT_ITEM_CLASSES : ITEM_CLASSES
    end

    def href_for(label)
      href_builder&.call(label)
    end
  end
end

# frozen_string_literal: true

module Ui
  # ⓘ toggle that opens a short explanation in a popover. A <details> element, so tap and keyboard work without JS.
  # `icon_only:` keeps the label for screen readers only.
  class InfoHintComponent < ViewComponent::Base
    include StrokeIconHelper

    ALIGN_CLASSES = { start: 'left-0', center: 'left-1/2 -translate-x-1/2', end: 'right-0' }.freeze

    def initialize(label:, text:, icon_only: false, align: :start)
      super()
      @label = label
      @text = text
      @icon_only = icon_only
      @align = align
    end

    private

    attr_reader :label, :text, :icon_only

    def popover_classes
      'absolute top-full z-20 mt-2 w-64 max-w-[calc(100vw-2rem)] rounded-lg border border-line bg-main p-3 ' \
        "text-xs/5 text-fg-secondary shadow-popover #{ALIGN_CLASSES.fetch(@align)}"
    end
  end
end

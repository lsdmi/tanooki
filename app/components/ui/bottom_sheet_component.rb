# frozen_string_literal: true

module Ui
  # Menu that opens as a bottom sheet below md and as a dropdown anchored to the trigger from md up
  # (Figma «Chapter actions menu» 10161:12120, «Library shelf picker» 10147:10814).
  # Behaviour lives in bottom_sheet_controller.js. The trigger slot is optional: anything can call `bottom-sheet#open`.
  class BottomSheetComponent < ViewComponent::Base
    ALIGN_CLASSES = { start: 'md:left-0', end: 'md:right-0' }.freeze

    PANEL_CLASSES = [
      'fixed inset-x-0 bottom-0 z-[70] max-h-[85dvh] translate-y-full overflow-y-auto',
      'rounded-t-2xl border border-b-0 border-line bg-main px-4 pt-3 pb-[max(1.5rem,env(safe-area-inset-bottom))]',
      'shadow-popover transition-transform duration-200 ease-out focus:outline-none',
      'md:absolute md:inset-x-auto md:bottom-auto md:top-full md:z-50 md:mt-2 md:max-h-none',
      'md:w-max md:min-w-60 md:max-w-80',
      'md:translate-y-0 md:rounded-xl md:border-b md:p-2 md:transition-none'
    ].join(' ').freeze

    renders_one :trigger

    def initialize(title:, id: nil, align: :start, html: {})
      super()
      @title = title
      @id = id || "bottom-sheet-#{SecureRandom.hex(4)}"
      @align = align.to_sym
      @html = html
      raise ArgumentError, "unknown align: #{align}" unless ALIGN_CLASSES.key?(@align)
    end

    private

    attr_reader :title, :id, :align, :html

    def root_attributes
      data = html.fetch(:data, {})
      html.except(:class, :data).merge(
        class: ['relative inline-block', html[:class]].compact.join(' '),
        data: data.merge(
          controller: [data[:controller], 'bottom-sheet'].compact.join(' '),
          action: [data[:action], 'keydown->bottom-sheet#keydown focusout->bottom-sheet#focusOut'].compact.join(' ')
        )
      )
    end

    def panel_classes
      "#{PANEL_CLASSES} #{ALIGN_CLASSES.fetch(align)}"
    end

    def title_id
      "#{id}-title"
    end
  end
end

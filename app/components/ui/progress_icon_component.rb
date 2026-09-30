# frozen_string_literal: true

module Ui
  # Chapter read state icon (Figma «Chapter Status», 4040:8658). Without a label it is decorative.
  class ProgressIconComponent < ViewComponent::Base
    STATES = %i[unread in_progress read].freeze

    SIZE_CLASSES = { sm: 'size-4', md: 'size-5', lg: 'size-6' }.freeze

    STATE_CLASSES = {
      unread: 'text-fg-muted',
      in_progress: 'text-fg-brand',
      read: 'text-status-success-solid'
    }.freeze

    def initialize(state:, size: :md, label: nil, html: {})
      super()
      @state = state.to_sym
      @size = size.to_sym
      @label = label
      @html = html
      raise ArgumentError, "unknown state: #{state}" unless STATES.include?(@state)
      raise ArgumentError, "unknown size: #{size}" unless SIZE_CLASSES.key?(@size)
    end

    private

    attr_reader :state, :size, :label, :html

    def wrapper_attributes
      accessibility = label.present? ? { role: 'img', aria: { label: } } : { aria: { hidden: true } }
      html.except(:class).merge(accessibility).merge(class: wrapper_classes)
    end

    def wrapper_classes
      ['inline-flex shrink-0 items-center justify-center', SIZE_CLASSES.fetch(size), STATE_CLASSES.fetch(state),
       html[:class]].compact.join(' ')
    end
  end
end

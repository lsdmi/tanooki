# frozen_string_literal: true

module Ui
  # 4 px read-progress bar (Figma «Volume header» and «Library entry»). Turns green with a check when complete.
  # Name it for screen readers with `html: { aria: { label: } }`.
  class MiniProgressBarComponent < ViewComponent::Base
    TONES = %i[brand licensed].freeze

    FILL_CLASSES = {
      brand: 'bg-brand',
      licensed: 'bg-status-licensed-solid',
      complete: 'bg-status-success-solid'
    }.freeze

    def initialize(read:, total:, tone: :brand, check: true, html: {})
      super()
      @total = [total.to_i, 0].max
      @read = read.to_i.clamp(0, @total)
      @tone = tone.to_sym
      @check = check
      @html = html
      raise ArgumentError, "unknown tone: #{tone}" unless TONES.include?(@tone)
    end

    private

    attr_reader :read, :total, :tone, :check, :html

    def complete?
      total.positive? && read == total
    end

    def show_check?
      check && complete? && tone == :brand
    end

    def percent
      total.zero? ? 0 : (read * 100.0 / total).round(1)
    end

    def fill_classes
      FILL_CLASSES.fetch(complete? && tone == :brand ? :complete : tone)
    end

    def wrapper_attributes
      html.except(:class, :aria).merge(
        class: ['inline-flex items-center gap-2', html[:class]].compact.join(' '),
        role: 'progressbar',
        aria: html.fetch(:aria, {}).merge(valuemin: 0, valuemax: total, valuenow: read)
      )
    end
  end
end

# frozen_string_literal: true

module Ui
  # Warning triangle for mature / 18+ tags (TagComponent, GenrePageTagComponent).
  class AdultWarningIconComponent < ViewComponent::Base
    def initialize(**options)
      super()
      @html_class = options.fetch(:class, 'h-3.5 w-3.5 shrink-0')
    end

    private

    attr_reader :html_class
  end
end

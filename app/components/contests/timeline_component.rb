# frozen_string_literal: true

module Contests
  # Contest lifecycle steps with the current phase highlighted.
  class TimelineComponent < ViewComponent::Base
    def initialize(presenter:)
      super()
      @presenter = presenter
    end

    private

    attr_reader :presenter

    def steps
      presenter.timeline_steps
    end
  end
end

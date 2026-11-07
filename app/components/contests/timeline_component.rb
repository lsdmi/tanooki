# frozen_string_literal: true

module Contests
  # Contest lifecycle steps with the current phase highlighted.
  class TimelineComponent < ViewComponent::Base
    def initialize(presenter:, embedded: false)
      super()
      @presenter = presenter
      @embedded = embedded
    end

    private

    attr_reader :presenter, :embedded

    def embedded? = embedded

    def steps
      presenter.timeline_steps
    end
  end
end

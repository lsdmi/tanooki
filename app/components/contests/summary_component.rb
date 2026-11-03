# frozen_string_literal: true

module Contests
  # Six at-a-glance facts under the hero.
  class SummaryComponent < ViewComponent::Base
    def initialize(presenter:)
      super()
      @presenter = presenter
    end

    private

    attr_reader :presenter
  end
end

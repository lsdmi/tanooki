# frozen_string_literal: true

require_relative 'preview_support'

module Contests
  class HeroComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    # @label Submissions hero
    def submissions
      presenter = PreviewSupport.sample_presenter(phase: :submissions)
      render(HeroComponent.new(contest: presenter.contest, presenter:))
    end

    # @label Announced hero
    def announced
      presenter = PreviewSupport.sample_presenter(phase: :announced)
      render(HeroComponent.new(contest: presenter.contest, presenter:))
    end
  end
end
